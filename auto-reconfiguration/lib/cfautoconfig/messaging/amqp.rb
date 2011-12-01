require 'cfruntime/properties'

module AutoReconfiguration
   module AMQP
     def self.included( base )
       base.send( :alias_method, :original_connect, :connect)
       base.send( :alias_method, :connect, :connect_with_cf )
     end

     def connect_with_cf(connection_options_or_string = {}, other_options = {}, &block)
       service_props = CFRuntime::CloudApp.service_props('rabbitmq')
        if(service_props.nil?)
          puts "No RabbitMQ service bound to app.  Skipping auto-reconfiguration."
          original_connect(connection_options_or_string, other_options, &block)
        else
          puts "Auto-reconfiguring AMQP."
          url_provided = false
          case connection_options_or_string
             when String then
               url_provided = true
               cfoptions = {}
             else
               cfoptions = connection_options_or_string
           end
           if service_props[:url] && url_provided
             #If user passed in a URL and we have a URL for service, use it
             original_connect(service_props[:url], other_options, &block)
           else
             cfoptions[:host] = service_props[:host]
             cfoptions[:port] = service_props[:port]
             cfoptions[:user] = service_props[:username]
             cfoptions[:pass] = service_props[:password]
             cfoptions[:vhost] = service_props[:vhost]
             original_connect(cfoptions, other_options, &block)
           end
        end
     end
   end
end