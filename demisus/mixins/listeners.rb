module Demisus
  module Mixins
    module Listeners
      def event_types
        raise NotImplementedError
      end

      def initialize_listeners
        # List of listeners per every event
        @listeners   = {}
        event_types.each {|e| @listeners[e] = []}
      end

      # Defines a new listener for the given event. When the event occurs, the
      # given block will be called with appropriate parameters
      def define_listener(event, &blk)
        event_sym = event.to_sym
        if event_types.include? event_sym
          @listeners[event_sym] << blk
        else
          raise UnknownEventError, "Unknown event #{event}"
        end
      end

      # Call the defined listeners for the given event, passing the given list
      # of params
      def call_listeners(event, params)
        @listeners[event.to_sym].each do |blk|
          blk.call(*params)
        end
      end
    end
  end
end
