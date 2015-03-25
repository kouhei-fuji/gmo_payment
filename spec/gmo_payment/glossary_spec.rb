# coding: utf-8
require 'spec_helper'

describe 'GmoPayment::GLOSSARY' do
  subject { GmoPayment::GLOSSARY }

  it 'is Hash<Symbol, String>' do
    expect(subject.keys).to all be_a(Symbol)
    expect(subject.values).to all be_a(String)
  end

  it 'is 60 pairs' do
    expect(subject.length).to eq(60)
  end
end
