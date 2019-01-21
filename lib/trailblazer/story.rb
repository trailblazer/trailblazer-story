require "trailblazer/story/version"
require "trailblazer/activity"

module Trailblazer
  module Story

    def self.extended(extender)
      extender.extend Trailblazer::Activity::Railway()
      extender.extend Trailblazer::Story::InputOutput
      extender.extend Trailblazer::Story::DSL
    end

    module DSL
      def step(builder:, defaults:, name:, **options)
        args = [
          builder,

          input: Trailblazer::Story::Input(name: name, hash: defaults),
          output: Trailblazer::Story::Output::ExtractModel(:model => name)
        ]

        super(*args)
      end

      def iterate(set:, name:, item_name:, &block)
        episode = Module.new do
          extend Story
          instance_exec(&block)
        end

        iterate = Iterate.new(episode: episode, set: set, item_name: item_name, name: name)

        step builder: iterate, name: name, defaults: ->(ctx, product:, _overrides:, **){ {product: product, _overrides: _overrides} } # FIXME
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

    class Iterate
      # module_function
      def initialize(episode:, set:, item_name:, name:)
        @episode = episode
        @set     = set
        @item_name = item_name
        @name = name
      end

      def call(ctx, **)
        set = @set.(ctx, **ctx)

        overrides = ctx[:_overrides][@name] || {} # FIXME: redundant in Input


        ctx[:model] =
          set.each_with_index.collect do |item, index|
            ctx = ctx.merge(:_overrides => {@item_name => overrides[index.to_s] || {}})

            # FIXME: use Subprocess or Sequence or whatever
            signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(@episode, [ctx, {}])

            ctx[@item_name]
          end
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
