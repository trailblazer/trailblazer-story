require "test_helper"
require "ostruct"

# linear stories where you can jump into any scenario and leave at any point or skip

class StoryTest < Minitest::Spec
  Product = OpenStruct
  Brand   = OpenStruct

  let(:bs) do
    bs = Module.new do
      extend Trailblazer::Activity::Railway()
      extend Trailblazer::Story::InputOutput
      extend Trailblazer::Story::DSL
      module_function


      def brand_defaults(ctx, **)
        {
          name: "Roxy",
        }
      end

      def product_defaults(ctx, brand:, supplier:, **) # DISCUSS: limit the args, without **?
        {
          name:     "Atomic",
          sku:      "123AAA",
          brand:    brand,
          supplier: supplier
        }
      end

      # def product(ctx, **options)
      #   ctx[:model] = Product.new(options)
      # end

      builders = Hash[
        {product: Product, brand: Brand}.collect do |name, constant|
          [name, ->(ctx, **options) { ctx[:model] = constant.new(options) }]
        end
      ]


      # step :brand
      # step :supplier
      # step :created_by#, factory: :super_admin
      # step :updated_by#, factory: :super_admin

      # step :product,
      step builder: builders[:brand], defaults: method(:brand_defaults), name: :brand
      step builder: builders[:product], defaults: method(:product_defaults), name: :product

      # step :product_with_size_break

    end
  end

  it "defaults options using the {default_options} data structure" do
    # ctx = {brand: "Volcom", supplier: "WC", _story_options: {}}
    ctx = {supplier: "WC", _overrides: {}}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

    ctx[:product].inspect.must_equal %{#<OpenStruct name="Atomic", sku="123AAA", brand=#<OpenStruct name=\"Roxy\">, supplier="WC">}
  end

  it "allows overriding defaults options via the override options" do
    ctx = {supplier: "WC", _overrides: {product: {name: "Atmospheric"}, brand: {name: "Volcom"}}}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

    ctx[:product].inspect.must_equal %{#<OpenStruct name="Atmospheric", sku="123AAA", brand=#<OpenStruct name=\"Volcom\">, supplier="WC">}
  end
end
