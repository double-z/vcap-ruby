require 'cfruntime/properties'

module AutoReconfiguration
  SUPPORTED_MONGO_VERSION = '1.2.0'
  module Mongo

    def self.included( base )
      base.send( :alias_method, :original_initialize, :initialize)
      base.send( :alias_method, :initialize, :initialize_with_cf )
      base.send( :alias_method, :original_db, :db)
      base.send( :alias_method, :db, :db_with_cf )
      base.send( :alias_method, :original_shortcut, :[])
      base.send( :alias_method, :[], :shortcut_with_cf )
    end

    def initialize_with_cf(host = nil, port = nil, opts = {})
      service_names = CFRuntime::CloudApp.service_names_of_type('mongodb')
      if service_names.length == 1
        @service_props = CFRuntime::CloudApp.service_props('mongodb')
        puts "Auto-reconfiguring MongoDB"
        @auto_config = true
        mongo_host = @service_props[:host]
        mongo_port = @service_props[:port]
        original_initialize mongo_host, mongo_port, opts
      else
        puts "Found #{service_names.length} mongo services. Skipping auto-reconfiguration."
        @auto_config = false
        original_initialize host, port, opts
      end
    end
     
    def db_with_cf(db_name, opts = {}) 
      if @auto_config && db_name != 'admin'
        db = original_db @service_props[:db], opts
        authenticate_with_cf(db)
      else
        original_db db_name, opts
      end
    end

    def shortcut_with_cf(db_name)
      if @auto_config && db_name != 'admin'
        db = original_shortcut(@service_props[:db])
        authenticate_with_cf(db)
      else
        db = original_shortcut(db_name)
      end
    end

    def authenticate_with_cf(db)
      mongo_username = @service_props[:username]
      mongo_password = @service_props[:password]
      db.authenticate mongo_username, mongo_password
      db
    end
  end
end
