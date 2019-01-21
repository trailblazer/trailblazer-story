require "trailblazer/story/version"
require "trailblazer/activity"

module Trailblazer
  module Story

    module DSL
      def step(builder:, defaults:, name:, **options)
        args = [
          builder,

          input: Trailblazer::Story::Input(name: name, hash: defaults),
          output: Trailblazer::Story::Output::ExtractModel(:model => name)
        ]

        super(*args)
      end
    end

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

    # TODO: allow deep_merge
    # TODO: default_options could be a "lazy" hash that only computes those values not provided via {overrides}.
    def self.Merge(default_options, overrides)
      default_options.merge(overrides)
    end

    def self.Input(hash:, name:, strategy: method(:Merge))
      ->(ctx, **) do # TODO: why do kw args not work here? {:_overrides}
        default_options = hash.(ctx, **ctx) # execute the input provider.

        options = strategy.(default_options, ctx[:_overrides][name] || {})

        Trailblazer::Context(options)
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
