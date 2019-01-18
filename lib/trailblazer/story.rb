require "trailblazer/story/version"
require "trailblazer/activity"

module Trailblazer
  module Story

    module InputOutput
      def step(task, options={})
        options = options.dup
        input, output = options.delete(:input), options.delete(:output)

        if input
          options = options.merge(Trailblazer::Activity::TaskWrap::VariableMapping.extension_for(

            Trailblazer::Activity::TaskWrap::Input.new(input),
            Trailblazer::Activity::TaskWrap::Output.new(output)) => true)
        end

        super(task, options)
      end
    end



    def self.Input(hash:)
      ->(ctx, **) do
        args = hash.(ctx, **ctx)
        Trailblazer::Context(args)
      end
    end

    module Input
      module_function
    end

    module Output
      module_function
      def ExtractModel(source2target)
        ->(original, ctx, **) do
          source2target.each do |source_key, target_key|
            original[target_key] = ctx[source_key]
          end

          original
        end
      end
    end
  end
end
