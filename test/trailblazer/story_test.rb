require "test_helper"
require "ostruct"

class StoryTest < Minitest::Spec
  Product = OpenStruct

  it do
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
        input: Trailblazer::Story::Input(hash: ->(ctx, brand:, supplier:, **) {
          {
          name:     "Atomic",
          sku:      "123AAA",
          brand:    brand,
          supplier: supplier
          }
        }),
        output: Trailblazer::Story::Output::ExtractModel(:model => :product)


      # step :product_with_size_break

    end

    ctx = {brand: "Volcom", supplier: "WC"}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

    ctx[:product].inspect.must_equal %{#<OpenStruct name="Atomic", sku="123AAA", brand="Volcom", supplier="WC">}
  end
end
