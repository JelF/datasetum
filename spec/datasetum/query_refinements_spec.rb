# frozen_string_literal: true

RSpec.describe Datasetum::QueryRefinements do
  using described_class

  context Object do
    let(:object) { instance_double(Object, :object) }

    shared_examples 'it matches single element' do
      it 'returns true if values equal' do
        expect(call(object)).to be_truthy
      end

      it 'returns false if values differs' do
        expect(call(instance_double(Object, :another_object))).to be_falsey
      end
    end

    shared_examples 'it matches itself' do
      it 'returns true' do
        expect(call(object)).to be_truthy
      end
    end

    describe '#safe_to_array' do
      it 'works as Array(x)' do
        expect(object.safe_to_array).to eq [object]
      end
    end

    describe '#match_elem?' do
      def call(elem)
        object.match_elem?(elem)
      end

      it_behaves_like 'it matches single element'
      it_behaves_like 'it matches itself'
    end

    describe '#match_any?' do
      def call(elems)
        object.match_any?(elems)
      end

      it_behaves_like 'it matches single element'
      it_behaves_like 'it matches itself'

      it 'returns true if any array element matches' do
        array = [object, instance_double(Object, :another_object)]
        expect(call(array)).to be_truthy
      end

      it 'returns false if no array elements matches' do
        array = [instance_double(Object, :another_object)]
        expect(call(array)).to be_falsey
      end

      it 'returns false on empty array' do
        expect(call([])).to be_falsey
      end
    end

    describe '#match_all?' do
      def call(elems)
        object.match_all?(elems)
      end

      it_behaves_like 'it matches single element'
      it_behaves_like 'it matches itself'

      it 'returns true if all array elements match' do
        array = [object, object]
        expect(call(array)).to be_truthy
      end

      it 'returns false if any array element does not match' do
        array = [object, instance_double(Object, :another_object)]
        expect(call(array)).to be_falsey
      end

      it 'returns false on empty array' do
        expect(call([])).to be_falsey
      end
    end
  end

  context Range do
    let(:range) { 1..10 }

    shared_examples 'it matches single element' do
      it 'returns true if value in range' do
        expect(call(9)).to be_truthy
      end

      it 'returns false if values differs' do
        expect(call(11)).to be_falsey
      end
    end

    shared_examples 'it matches itself' do
      it 'returns true' do
        expect(call(range)).to be_truthy
      end
    end

    describe '#safe_to_array' do
      it 'works as to_a' do
        expect(range.safe_to_array).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
      end
    end

    describe '#match_elem?' do
      def call(elem)
        range.match_elem?(elem)
      end

      it_behaves_like 'it matches single element'
    end

    describe '#match_any?' do
      it_behaves_like 'it matches itself'

      def call(elems)
        range.match_any?(elems)
      end

      it_behaves_like 'it matches single element'

      it 'returns true if any array element matches' do
        expect(call([9, 11])).to be_truthy
      end

      it 'returns false if no array elements matches' do
        array = [11]
        expect(call(array)).to be_falsey
      end

      it 'returns false on empty array' do
        expect(call([])).to be_falsey
      end
    end

    describe '#match_all?' do
      def call(elems)
        range.match_all?(elems)
      end

      it_behaves_like 'it matches single element'
      it_behaves_like 'it matches itself'

      it 'returns true if all array elements match' do
        array = [1, 2]
        expect(call(array)).to be_truthy
      end

      it 'returns false if any array element does not match' do
        expect(call([9, 11])).to be_falsey
      end

      it 'returns false on empty array' do
        expect(call([])).to be_falsey
      end
    end
  end

  context Array do
    let(:array) do
      [
        instance_double(Object, :first_element),
        instance_double(Object, :second_element)
      ]
    end

    shared_examples 'it matches single element' do
      it 'returns true if value matches first element' do
        expect(call(array[0])).to be_truthy
      end

      it 'returns true if value matches second element' do
        expect(call(array[1])).to be_truthy
      end

      it 'returns false if values differs' do
        expect(call(instance_double(Object, :other_element))).to be_falsey
      end
    end

    shared_examples 'it matches itself' do
      it 'returns true' do
        expect(call(array)).to be_truthy
      end
    end

    describe '#safe_to_array' do
      it 'returns itself' do
        expect(array.safe_to_array).to eq array
      end
    end

    describe '#match_elem?' do
      def call(elem)
        array.match_elem?(elem)
      end

      it_behaves_like 'it matches single element'
    end

    describe '#match_any?' do
      it_behaves_like 'it matches itself'

      def call(elems)
        array.match_any?(elems)
      end

      it_behaves_like 'it matches single element'

      it 'returns true if any array element matches' do
        expect(call([array[0], instance_double(Object, :other_element)]))
          .to be_truthy
      end

      it 'returns false if no array elements matches' do
        expect(call([instance_double(Object, :other_element)]))
          .to be_falsey
      end

      it 'returns false on empty array' do
        expect(call([])).to be_falsey
      end
    end

    describe '#match_all?' do
      def call(elems)
        array.match_all?(elems)
      end

      it_behaves_like 'it matches single element'
      it_behaves_like 'it matches itself'

      it 'returns true if all array elements match' do
        expect(call(array[0..0])).to be_truthy
      end

      it 'returns false if any array element does not match' do
        expect(call([array[0], instance_double(Object, :other_element)]))
          .to be_falsey
      end

      it 'returns false on empty array' do
        expect(call([])).to be_falsey
      end
    end
  end

  context Object do
    let(:object) { instance_double(Object, :object) }
    let(:proc) { ->(x) { x == object } }

    shared_examples 'it matches single element' do
      it 'returns true if values equal' do
        expect(call(object)).to be_truthy
      end

      it 'returns false if values differs' do
        expect(call(instance_double(Object, :another_object))).to be_falsey
      end
    end

    describe '#safe_to_array' do
      it 'works as Array(x)' do
        expect(proc.safe_to_array).to eq [proc]
      end
    end

    describe '#match_elem?' do
      def call(elem)
        proc.match_elem?(elem)
      end

      it_behaves_like 'it matches single element'
    end

    describe '#match_any?' do
      def call(elems)
        proc.match_any?(elems)
      end

      it_behaves_like 'it matches single element'

      it 'returns true if any array element matches' do
        array = [object, instance_double(Object, :another_object)]
        expect(call(array)).to be_truthy
      end

      it 'returns false if no array elements matches' do
        array = [instance_double(Object, :another_object)]
        expect(call(array)).to be_falsey
      end

      it 'returns false on empty array' do
        expect(call([])).to be_falsey
      end
    end

    describe '#match_all?' do
      def call(elems)
        proc.match_all?(elems)
      end

      it_behaves_like 'it matches single element'

      it 'returns true if all array elements match' do
        array = [object, object]
        expect(call(array)).to be_truthy
      end

      it 'returns false if any array element does not match' do
        array = [object, instance_double(Object, :another_object)]
        expect(call(array)).to be_falsey
      end

      it 'returns false on empty array' do
        expect(call([])).to be_falsey
      end
    end
  end
end
