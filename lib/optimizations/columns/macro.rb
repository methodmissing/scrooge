module Scrooge
  module Optimizations 
    module Columns
      module Macro
        
        class << self
          
          # Inject into ActiveRecord
          #
          def install!
            if scrooge_installable?
              ActiveRecord::Base.send( :extend,  SingletonMethods )
              ActiveRecord::Base.send( :include, InstanceMethods )              
            end  
          end
      
          private
          
            def scrooge_installable?
              !ActiveRecord::Base.included_modules.include?( InstanceMethods )
            end
         
        end
        
      end
      
      module SingletonMethods
     
        ScroogeBlankString = "".freeze
        ScroogeComma = ",".freeze 
        ScroogeRegexSanitize = /(?:LIMIT|WHERE|FROM|GROUP\s*BY|HAVING|ORDER\s*BY|PROCEDURE|FOR\s*UPDATE|INTO\s*OUTFILE).*/i
        ScroogeRegexJoin = /(?:left|inner|outer|cross)*\s*(?:straight_join|join)/i
        
        @@scrooge_select_regexes = {}
        
        # Augment a given callsite signature with a column / attribute.
        #
        def scrooge_seen_column!( callsite_signature, attr_name )
          scrooge_callsite( callsite_signature ).column!( attr_name )
        end        
        
        # Generates a SELECT snippet for this Model from a given Set of columns
        #
        def scrooge_select_sql( set )
          set.map{|a| attribute_with_table( a ) }.join( ScroogeComma )
        end        
        
        # Marshal.load
        # 
        def _load(str)
          Marshal.load(str)
        end
        
        # Efficient reloading - get the hash with missing attributes directly from the 
        # underlying connection.
        #
        def scrooge_reload( p_key, missing_columns )
          attributes = connection.send( :select, "SELECT #{scrooge_select_sql(missing_columns)} FROM #{quoted_table_name} WHERE #{quoted_table_name}.#{primary_key} = '#{p_key}'" ).first
          attributes ? attributes : raise( ActiveRecord::RecordNotFound )
        end
        
        private

          # Only scope n-1 rows by default.
          # Stephen: Temp. relaxed the LIMIT constraint - please advise.
          def scope_with_scrooge?( sql )
            sql =~ scrooge_select_regex && 
            column_names.include?(self.primary_key.to_s) &&
            sql !~ ScroogeRegexJoin
          end
        
          # Find through callsites.
          #
          def find_by_sql_with_scrooge( sql, callsite_sig = nil )
            callsite_sig ||= callsite_signature( caller, callsite_sql( sql ) )
            callsite_columns = scrooge_callsite(callsite_sig).columns
            callsite_associations = scrooge_callsite(callsite_sig).associations
            sql = sql.gsub(scrooge_select_regex, "SELECT #{scrooge_select_sql(callsite_columns)} FROM")
            connection.select_all(sanitize_sql(sql), "#{name} Load Scrooged").collect! do |record|
              instantiate( ScroogedAttributes.setup(record, callsite_columns, callsite_associations, self, callsite_sig) )
            end
          end        
        
          # Find and instantiate as usual
          #
          def find_by_sql_without_scrooge( sql )
            connection.select_all(sanitize_sql(sql), "#{name} Load").collect! do |record|
              instantiate( UnscroogedAttributes.setup(record) )
            end
          end

          # Generate a regex that respects the table name as well to catch
          # verbose SQL from JOINS etc.
          # 
          def scrooge_select_regex
            @@scrooge_select_regexes[self.table_name] ||= Regexp.compile( "SELECT (`?(?:#{table_name})?`?.?\\*) FROM" )
          end

          # Trim any conditions
          #
          def callsite_sql( sql )
            sql.gsub(ScroogeRegexSanitize, ScroogeBlankString)
          end

      end
      
      module InstanceMethods
     
        def self.included( base )
          base.alias_method_chain :delete, :scrooge
          base.alias_method_chain :destroy, :scrooge
          base.alias_method_chain :respond_to?, :scrooge
          base.alias_method_chain :attributes_from_column_definition, :scrooge
          base.alias_method_chain :becomes, :scrooge
        end
        
        # Is this instance being handled by scrooge?
        #
        def scrooged?
          @attributes.is_a?(ScroogedAttributes)
        end        
        
        # Delete should fully load all the attributes before the @attributes hash is frozen
        #
        def delete_with_scrooge
          scrooge_fetch_remaining
          delete_without_scrooge
        end        
      
        # Destroy should fully load all the attributes before the @attributes hash is frozen
        #
        def destroy_with_scrooge
          scrooge_fetch_remaining
          destroy_without_scrooge
        end      
        
        # Augment callsite info for new model class when using STI
        #
        def becomes_with_scrooge(klass)
          if scrooged?
            self.class.scrooge_callsite(@attributes.callsite_signature).columns.each do |attrib|
              klass.scrooge_seen_column!(@attributes.callsite_signature, attrib)
            end
          end
          becomes_without_scrooge(klass)
        end     

        # Marshal
        # force a full load if needed, and remove any possibility for missing attr flagging
        #
        def _dump(depth)
          scrooge_fetch_remaining
          scrooge_dump_flag_this
          str = Marshal.dump(self)
          scrooge_dump_unflag_this
          str
        end
        
        # Enables us to use Marshal.dump inside our _dump method without an infinite loop
        #
        def respond_to_with_scrooge?(symbol, include_private=false)
          if symbol == :_dump && scrooge_dump_flagged?
            false
          else
            respond_to_without_scrooge?(symbol, include_private)
          end
        end

        private

          # Flag Marshal dump in progress
          #
          def scrooge_dump_flag_this
            Thread.current[:scrooge_dumping_objects] ||= []
            Thread.current[:scrooge_dumping_objects] << object_id
          end

          # Flag Marhsal dump not in progress
          #
          def scrooge_dump_unflag_this
            Thread.current[:scrooge_dumping_objects].delete(object_id)
          end

          # Flag scrooge as dumping ( excuse my French )
          #
          def scrooge_dump_flagged?
            Thread.current[:scrooge_dumping_objects] &&
            Thread.current[:scrooge_dumping_objects].include?(object_id)
          end

          # Fetch any missing attributes
          #
          def scrooge_fetch_remaining
            @attributes.fetch_remaining if scrooged?
          end
          
          # New objects should get an UnscroogedAttributes as their @attributes hash
          #
          def attributes_from_column_definition_with_scrooge
            UnscroogedAttributes.setup(attributes_from_column_definition_without_scrooge)
          end
        
      end
      
    end
  end
end