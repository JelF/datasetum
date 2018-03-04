# frozen_string_literal: true

RSpec.describe Datasetum::Dataset do
  subject(:dataset) do
    # Struct provides .[] method which interfere with described module
    Class.new do
      extend Datasetum::Dataset
      attr_accessor :foo

      def initialize(foo)
        self.foo = foo
      end
    end
  end

  let(:data) { [dataset.new(123), dataset.new(456)] }

  before 'specify data as data source' do
    dataset.send(:data_source) { data }
  end

  it 'loads data' do
    expect(dataset.all).to match [
      ->(x) { x.foo == 123 },
      ->(x) { x.foo == 456 }
    ]
  end

  describe '#query' do
    context 'with equality runner' do
      before { dataset.send(:queries, :foo) }

      it 'filters by exact value' do
        expect(dataset.query(foo: 123)).to match [->(x) { x.foo == 123 }]
      end

      it 'finds by array of values' do
        expect(dataset.query(foo: [123, 456])).to match [
          ->(x) { x.foo == 123 },
          ->(x) { x.foo == 456 }
        ]
      end

      it 'finds by range of values' do
        expect(dataset.query(foo: 100..500)).to match [
          ->(x) { x.foo == 123 },
          ->(x) { x.foo == 456 }
        ]
      end

      it 'finds by proc' do
        expect(dataset.query(foo: ->(x) { x < 200 }))
          .to match [->(x) { x.foo == 123 }]
      end
    end

    context 'with block runner' do
      using Datasetum::QueryRefinements

      let(:data) { [dataset.new([1, 2]), dataset.new([3, 4])] }

      before do
        dataset.send(:queries, :foo) { expression.match_all?(field) }
      end

      it 'finds by expression using block' do
        expect(dataset.query(foo: 2..5)).to match [->(x) { x.foo == [3, 4] }]
      end
    end

    context 'with wrong field' do
      before { dataset.send(:queries, :foo) }

      it 'raises error' do
        expect { dataset.query(bar: 123) }.to raise_error(
          Datasetum::QueringError,
          /do not queries :bar. Available queries keys are \[:foo\]\z/
        )
      end
    end

    context 'with primary_column' do
      before do
        dataset.send(:queries, :foo)
        dataset.send(:primary_column=, :foo)
      end

      it 'filters by exact value' do
        expect(dataset.query(123)).to match [->(x) { x.foo == 123 }]
      end

      it 'finds by array of values' do
        expect(dataset.query([123, 456])).to match [
          ->(x) { x.foo == 123 },
          ->(x) { x.foo == 456 }
        ]
      end
    end

    context 'without primary_column' do
      before { dataset.send(:queries, :foo) }

      it 'raises error' do
        expect { dataset.query(123) }.to raise_error(
          Datasetum::QueringError, Regexp.new(<<~REGEXP.tr("\n", ''))
            \\A
            primary column not defined for
            .+,\\s
            123 should be either hash or array of hashes
            \\z
          REGEXP
        )
      end
    end
  end

  describe '#[]' do
    before { dataset.send(:queries, :foo) }

    it 'returns nil' do
      expect(dataset[foo: []]).to be_nil
    end

    it 'returns signle value' do
      expect(dataset[foo: 123].foo).to eq 123
    end

    it 'raises on multiple values' do
      expect { dataset[foo: [123, 456]] }.to raise_error(
        Datasetum::QueringError,
        /\.query\({:foo=>\[123, 456\]}\) returned more then one record\z/
      )
    end
  end

  describe '#fetch' do
    before { dataset.send(:queries, :foo) }

    it 'returns nil' do
      expect { dataset.fetch(foo: []) }.to raise_error(
        Datasetum::QueringError,
        /\.query\({:foo=>\[\]}\) returned nothing\z/
      )
    end

    it 'returns signle value' do
      expect(dataset.fetch(foo: 123).foo).to eq 123
    end

    it 'raises on multiple values' do
      expect { dataset.fetch(foo: [123, 456]) }.to raise_error(
        Datasetum::QueringError,
        /\.query\({:foo=>\[123, 456\]}\) returned more then one record\z/
      )
    end
  end
end
