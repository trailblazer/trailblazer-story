require "trailblazer/story/version"
require "trailblazer/activity/dsl/linear"
require "forwardable"

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
        ext, _ = Trailblazer::Activity::DSL::Linear::VariableMapping(input: input, output: output)

        options = options.merge(
          extensions: [ext],
          id:         name,
        )

        @state.step(builder, **options)
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
      ->(ctx, _overrides:, **) do
        # default_options = hash.(ctx, **ctx, **(_overrides[name] || {})) # execute the input provider.

        # TODO: this doesn't pass overrides into the defaulter, and will result in {detail_defaults} never see a different {name}
        default_options = hash.(ctx, **ctx) # execute the input provider.


        options = strategy.(default_options, _overrides[name] || {})

        options
        # Trailblazer::Context(options)
      end
    end


    module Input
      module_function
    end

    module Output
      module_function
      def ExtractModel(source2target)
        return source2target

        puts "@@@@@ #{source2target.inspect}"
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
