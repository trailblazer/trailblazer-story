require "trailblazer/story/version"
require "trailblazer/activity"
require "trailblazer/activity/dsl/linear"

module Trailblazer
  class Story

    def self.initialize!(state=Class.new(Trailblazer::Activity::Railway))
      @state = state
    end

    initialize!

    # TODO
    def self.inherited(subclass)
      subclass.initialize!(Class.new(@state)) # TODO: copy state, but since it's immutable, this should be working for now.
    end

    class << self
      extend Forwardable
      def_delegators :@state, :call
    end

    module DSL
      def step(builder:, defaults:, name:, **options)
        input  = Trailblazer::Story::Input(name: name, hash: defaults)
        output = Trailblazer::Story::Output::ExtractModel(:model => name)

        options = options.merge(
          extensions: [Trailblazer::Activity::TaskWrap::VariableMapping::Extension(input, output)],
          id:         name,
        )

        @state.send(:step, builder, **options)
      end

      def iterate(set:, name:, item_name:, inject_as:, &block)
        episode = Class.new(Story)
        episode.instance_exec(&block)

        iterate = Iterate.new(episode: episode, set: set, item_name: item_name, name: name, inject_as: inject_as)

        step builder: iterate, name: name, defaults: ->(ctx, **){ ctx }, id: name # FIXME is it a good idea to default here at all?
      end
    end

    class Iterate
      # module_function
      def initialize(episode:, set:, item_name:, name:, inject_as:)
        @episode = episode
        @set     = set
        @item_name = item_name
        @name = name
        @inject_as = inject_as
      end

      def call(ctx, **)
        set = @set.(ctx, **ctx)

        overrides = ctx[:_overrides][@name] || {} # FIXME: redundant in Input

        ctx[:model] =
          set.each_with_index.collect do |item, index|
            ctx = ctx.merge(:_overrides => {@item_name => overrides[index.to_s] || {}}, @inject_as => item)

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


    extend Trailblazer::Story::DSL
  end
end
