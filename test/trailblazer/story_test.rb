require "test_helper"
require "ostruct"

# linear stories where you can jump into any scenario and leave at any point or skip

class StoryTest < Minitest::Spec
  Product = OpenStruct
  Brand   = OpenStruct
  Item    = OpenStruct
  ProductRelease = OpenStruct
  SizeBreak = OpenStruct
  Detail = OpenStruct

  let(:bs) do
    bs = Class.new(Trailblazer::Story) do
      def self.brand_defaults(ctx, **)
        {
          name: "Roxy",
        }
      end

      def self.product_defaults(ctx, brand:, supplier:, **) # DISCUSS: limit the args, without **?
        {
          name:     "Atomic",
          sku:      "123AAA",
          brand:    brand,
          supplier: supplier
        }
      end

      def self.item_defaults(ctx, **)
        {
          # name:     "Atomic",
        }
      end

      def self.detail_defaults(ctx, name: "Dutch Nuggets", **)
        {
          name: name,
          sku:  "#{name}-1",
        }
      end

      def self.product_release_defaults(ctx, product:, **)
        {
          # name:     "Atomic",
          product: product,
          available_months: ["DEC19", "JAN20", "FEB20"],
        }
      end


      # def product(ctx, **options)
      #   ctx[:model] = Product.new(options)
      # end

      builders = Hash[
        {product: Product, brand: Brand, item: Item, product_release: ProductRelease, size_break: SizeBreak, detail: Detail}.collect do |name, constant|
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
      step builder: builders[:item], defaults: method(:item_defaults), name: :item
      step builder: builders[:detail], defaults: method(:detail_defaults), name: :detail

      # # product.size_breaks
      iterate set: ->(ctx, **){["S", "M", "L"]}, name: :size_breaks, item_name: :size_break, inject_as: :size do
        def self.size_break_defaults(ctx, product:, size:, **)
          {
            product: product,
            size: size,
            color: "RED",
          }
        end

        step builder: builders[:size_break], defaults: method(:size_break_defaults), name: :size_break
      end

      step builder: builders[:product_release], defaults: method(:product_release_defaults), name: :product_release

      # step :product_with_size_break
    end
  end

  it "defaults options using the {default_options} data structure" do
    # ctx = {brand: "Volcom", supplier: "WC", _story_options: {}}
    ctx = {supplier: "WC", _overrides: {}}

    # pp bs.instance_variable_get(:@state).to_h

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

    pp ctx

    ctx[:product].inspect.must_equal %{#<OpenStruct name="Atomic", sku="123AAA", brand=#<OpenStruct name=\"Roxy\">, supplier="WC">}
    ctx[:detail].inspect.must_equal %{#<OpenStruct name=\"Dutch Nuggets\", sku=\"Dutch Nuggets-1\">}
  end

  it "allows overriding defaults options via the override options" do
    ctx = {supplier: "WC", _overrides: {product: {name: "Atmospheric"}, brand: {name: "Volcom"}, detail: {name: "Bad Religion"}}}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

    ctx[:product].inspect.must_equal %{#<OpenStruct name="Atmospheric", sku="123AAA", brand=#<OpenStruct name=\"Volcom\">, supplier="WC">}
    ctx[:detail].inspect.must_equal %{#<OpenStruct name=\"Bad Religion\", sku=\"Bad Religion-1\">}
  end
  # TODO: bla_defaults(...**options) => should allow injecting more values, such as {color}

  it "doesn't leak defaults into the following episode (both have {:name} attribute)" do
    ctx = {supplier: "WC", _overrides: {}}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

    ctx[:product].inspect.must_equal %{#<OpenStruct name="Atomic", sku="123AAA", brand=#<OpenStruct name=\"Roxy\">, supplier="WC">}
    ctx[:item].inspect.must_equal %{#<OpenStruct>}
  end

  # it "allows nested flows" do
  #   ctx = {supplier: "WC", _overrides: {}}

  it "sets static values from {:input}" do
    ctx = {brand: "Volcom", supplier: "WC"}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

# FIXME: {:supplier} shouldn't be here!
    ctx[:product_release].inspect.must_equal %{#<OpenStruct product=#<OpenStruct name=\"Atomic\", sku=\"123AAA\", brand=#<OpenStruct name=\"Roxy\">, supplier=\"WC\">, available_months=[\"DEC19\", \"JAN20\", \"FEB20\"]>}
  end

  it "Iterate" do
    ctx = {supplier: "WC", _overrides: {}}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

# FIXME: {:supplier} shouldn't be here!
    ctx[:size_breaks].inspect.must_equal %{[#<OpenStruct product=#<OpenStruct name=\"Atomic\", sku=\"123AAA\", brand=#<OpenStruct name=\"Roxy\">, supplier=\"WC\">, size=\"S\", color=\"RED\">, #<OpenStruct product=#<OpenStruct name=\"Atomic\", sku=\"123AAA\", brand=#<OpenStruct name=\"Roxy\">, supplier=\"WC\">, size=\"M\", color=\"RED\">, #<OpenStruct product=#<OpenStruct name=\"Atomic\", sku=\"123AAA\", brand=#<OpenStruct name=\"Roxy\">, supplier=\"WC\">, size=\"L\", color=\"RED\">]}
  end
  it "Iterate allows {:_overrides}" do
    ctx = {supplier: "WC", _overrides: {size_breaks:{"1" => {color: "PINK"}}}}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

# FIXME: {:supplier} shouldn't be here!
    ctx[:size_breaks].inspect.must_equal %{[#<OpenStruct product=#<OpenStruct name=\"Atomic\", sku=\"123AAA\", brand=#<OpenStruct name=\"Roxy\">, supplier=\"WC\">, size=\"S\", color=\"RED\">, #<OpenStruct product=#<OpenStruct name=\"Atomic\", sku=\"123AAA\", brand=#<OpenStruct name=\"Roxy\">, supplier=\"WC\">, size=\"M\", color=\"PINK\">, #<OpenStruct product=#<OpenStruct name=\"Atomic\", sku=\"123AAA\", brand=#<OpenStruct name=\"Roxy\">, supplier=\"WC\">, size=\"L\", color=\"RED\">]}
  end


# TODO: raise when :inject_as and :item_name are identical for {iterate}
  it "overrides values from {:input} when passed explicitly" do
    ctx = {brand: "Volcom", supplier: "WC", name: "Aromatic"}

    signal, (ctx, _) = Trailblazer::Activity::TaskWrap.invoke(bs, [ctx, {}])

    ctx[:product].inspect.must_equal %{#<OpenStruct name="Aromatic", sku="123AAA", brand="Volcom", supplier="WC">}
  end
end
