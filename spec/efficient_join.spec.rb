require 'efficient_join'
require 'benchmark'
require 'pg'

RSpec.describe EfficientJoin, '#join' do
  it 'can handle bigint >= 2**61 and < 2**64' do
    expect(
      EfficientJoin.join([2**62])
    ).to eq "#{2**62}"
  end

  it 'can join arrays of strings and integers' do
    expect(
      EfficientJoin.join(['hello', 123, 'world'])
    ).to eq 'hello,123,world'
  end

  it 'works, I guess' do
    expect(
      EfficientJoin.join([])
    ).to eq ''

    expect(
      EfficientJoin.join([2, 3, 4])
    ).to eq '2,3,4'

    expect(
      EfficientJoin.join(
        [2, 3, 4, 5], separator: '-', item_prefix: '[', item_suffix: ']'
      )
    ).to eq '[2]-[3]-[4]-[5]'
  end
end

RSpec.describe EfficientJoin, '#join_pg_array' do
  it 'works, I guess' do
    expect(
      EfficientJoin.join_pg_array([2, 3, 4, 5])
    ).to eq '{2,3,4,5}'
  end
end

RSpec.describe EfficientJoin, '#join' do
  it 'is faster than Array#join' do
    a = (0..1_000_000).to_a

    array_join = Benchmark.measure { a.join(',') }
    effic_join = Benchmark.measure { EfficientJoin.join(a) }
    join_speedup = array_join.total / effic_join.total
    puts "Speed up over Array#join: #{join_speedup}"
    expect(join_speedup).to be > 2
  end
end

RSpec.describe EfficientJoin, '#join_pg_array' do
  it 'is faster than PG::TextEncoder::Array.new.encode' do
    a = (0..1_000_000).to_a

    array_join = Benchmark.measure { PG::TextEncoder::Array.new.encode(a) }
    effic_join = Benchmark.measure { EfficientJoin.join_pg_array(a) }
    join_speedup = array_join.total / effic_join.total
    puts "Speed up over PG::TextEncoder::Array.new.encode: #{join_speedup}"
    expect(join_speedup).to be > 2
  end
end
