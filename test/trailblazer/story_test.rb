require "test_helper"
require "ostruct"

class StoryTest < Minitest::Spec
  Product = OpenStruct

  let(:bs) do
    bs = Module.new do
      extend Trailblazer::Activity::Railway()
      extend Trailblazer::Story::InputOutput
      module_function

      def product(ctx, **options)
        ctx[:model] = Product.new(options)
      end


      # step :brand
      # step :supplier
      # step :created_by#, factory: :super_admin
      # step :updated_by#, factory: :super_admin

      # step :product,
      step method(:product),
        input: Trailblazer::Story::Input(name: :product, hash: ->(ctx, brand:, supplier:, **user_options) {
        # input: Trailblazer::Story::Input(hash: ->(ctx, brand:, supplier:, _story_options:, **user_options) {
          default_options =
          {
          name:     "Atomic",
          sku:      "123AAA",
          brand:    brand,
          supplier: supplier
          }

          # user_options = _story_options[:product] || {}


        }),
        output: Trailblazer::Story::Output::ExtractModel(:model => :product)


      # step :product_with_size_break

    end
  end

  it "defaults options using the {default_options} data structure" do
    # ctx = {brand: "Volcom", supplier: "WC", _story_options: {}}
    ctx = {brand: "Volcom", supplier: "WC", _overrides: {}}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

    ctx[:product].inspect.must_equal %{#<OpenStruct name="Atomic", sku="123AAA", brand="Volcom", supplier="WC">}
  end

  it "allows overriding defaults options via the override options" do
    ctx = {brand: "Volcom", supplier: "WC", _overrides: {product: {name: "Atmospheric"}}}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

    ctx[:product].inspect.must_equal %{#<OpenStruct name="Atmospheric", sku="123AAA", brand="Volcom", supplier="WC">}
  end
end
