module Scrooge
  module Optimizations 
    module Columns
      module Macro
        
        class << self
          
          # Inject into ActiveRecord
          #
          def install!
            if scrooge_installable?
              ActiveRecord::Base.send( :extend,  Scrooge::Optimizations::Columns::SingletonMethods )
              ActiveRecord::Base.send( :include, Scrooge::Optimizations::Columns::InstanceMethods )
            end  
          end
      
          private
          
            def scrooge_installable?
              !ActiveRecord::Base.included_modules.include?( Scrooge::Optimizations::Columns::InstanceMethods )
            end
         
        end
        
      end
      
      module SingletonMethods
        
        ScroogeBlankString = "".freeze
        ScroogeComma = ",".freeze 
        ScroogeRegexConditions = /WHERE.*/i
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
          def find_by_sql_with_scrooge( sql )
            callsite_signature = (caller[ActiveRecord::Base::ScroogeCallsiteSample] << truncate_conditions( sql )).hash
            callsite_set = scrooge_callsite(callsite_signature).columns
            sql = sql.gsub(scrooge_select_regex, "SELECT #{scrooge_select_sql(callsite_set)} FROM")
            result = connection.select_all(sanitize_sql(sql), "#{name} Load Scrooged").collect! do |record|
              instantiate( Scrooge::Optimizations::Columns::AttributesProxy.setup(record, callsite_set, self, callsite_signature) )
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
            def truncate_conditions( sql )
              sql.gsub(ScroogeRegexConditions, ScroogeBlankString)
            end
                    
      end
      
      module InstanceMethods
        
        def self.included( klass )
          klass.class_eval do
            # this is executed after included methods are defined, so can't alias here
          end
        end
        
        # Is this instance being handled by scrooge?
        #
        def scrooged?
          @attributes.is_a?(Scrooge::Optimizations::Columns::AttributesProxy)
        end        
        
        # Delete should fully load all the attributes before the @attributes hash is frozen
        #
        #alias_method :delete_without_scrooge, :delete
        def delete
          scrooge_fetch_remaining
          delete_without_scrooge
        end        
      
        # Destroy should fully load all the attributes before the @attributes hash is frozen
        #
        #alias_method :destroy_without_scrooge, :destroy
        def destroy
          scrooge_fetch_remaining
          destroy_without_scrooge
        end      
        
        # Augment callsite info for new model class when using STI
        #
        def becomes(klass)
          returning klass.new do |became|
            became.instance_variable_set("@attributes", @attributes)
            became.instance_variable_set("@attributes_cache", @attributes_cache)
            became.instance_variable_set("@new_record", new_record?)
            if scrooged?
              self.class.scrooge_callsite(@attributes.callsite_signature).columns.each do |attrib|
                became.class.scrooge_seen_column!(@attributes.callsite_signature, attrib)
              end
            end
          end
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
        #alias_method :respond_to_without_scrooge, :respond_to?
        def respond_to?(symbol, include_private=false)
          if symbol == :_dump && scrooge_dump_flagged?
            false
          else
            respond_to_without_scrooge(symbol, include_private)
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
        
      end
      
    end
  end
end