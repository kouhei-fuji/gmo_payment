# coding: utf-8

shared_examples 'validation of length <= n' do |items, value_type, n|
  context "with length <= #{n}" do
    let(:value) { "#{value_type}" * n }
    items.each do |key|
      let(:key) { key }
      it { is_expected.to be(true) }
    end
  end
  context "with length > #{n}" do
    let(:value) { "#{value_type}" * (n + 1) }
    items.each do |key|
      let(:key) { key }
      it { is_expected.to be(false) }
    end
  end
end

shared_examples 'validation of length >= n' do |items, value_type, n|
  context "with length >= #{n}" do
    let(:value) { "#{value_type}" * n }
    items.each do |key|
      let(:key) { key }
      it { is_expected.to be(true) }
    end
  end
  context "with length < #{n}" do
    let(:value) { "#{value_type}" * (n - 1) }
    items.each do |key|
      let(:key) { key }
      it { is_expected.to be(false) }
    end
  end
end

shared_examples 'validation of number' do |items, n|
  context 'with number' do
    let(:value) { '1' * n }
    items.each do |key|
      let(:key) { key }
      it { is_expected.to be(true) }
    end
  end
  context 'with not number' do
    let(:value) { 'not_number' }
    items.each do |key|
      let(:key) { key }
      it { is_expected.to be(false) }
    end
  end
end

shared_examples 'validation of value including' do |items, array|
  context "with #{array.join(' or ')}" do
    items.each do |key|
      let(:key) { key }
      array.each do |value|
        let(:value) { value }
        it { is_expected.to be(true) }
      end
    end
  end
  context "with not #{array.join(' or ')}" do
    items.each do |key|
      let(:key) { key }
      let(:value) { 'x' }
      it { is_expected.to be(false) }
    end
  end
end
