require 'efficient_join'
require 'benchmark'
require 'pg'
require 'memory_profiler'

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
      EfficientJoin.join(["some\x00null", "foo\x00bar"])
    ).to eq "some\x00null,foo\x00bar"

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

RSpec.describe EfficientJoin, '#join_pg_array' do
  it 'is faster than PG::TextEncoder::Array.new.encode' do
    a = (0..4_000_000).to_a
    b = (0..10_000).to_a

    t = Time.now
    m = MemoryProfiler.report do
      EfficientJoin.join_pg_array(a)
    end
    puts "EfficientJoin: whole 4M allocated #{m.total_allocated} objects, used #{m.total_allocated_memsize / 1024**2} MiB, took #{Time.now - t} seconds"

    t = Time.now
    m = MemoryProfiler.report do
      a.each_slice(1_000_000) do |slice|
        EfficientJoin.join_pg_array(slice)
        GC.start
      end
    end
    puts "EfficientJoin: 4M in 1M batches allocated #{m.total_allocated} objects, used #{m.total_allocated_memsize / 1024**2} MiB, took #{Time.now - t} seconds"

    t = Time.now
    m = MemoryProfiler.report do
      a.each_slice(10_000) do |slice|
        EfficientJoin.join_pg_array(slice)
        GC.start
      end
    end
    puts "EfficientJoin: 4M in 10k batches allocated #{m.total_allocated} objects, used #{m.total_allocated_memsize / 1024**2} MiB, took #{Time.now - t} seconds"

    t = Time.now
    m = MemoryProfiler.report do
      PG::TextEncoder::Array.new.encode(b)
    end
    puts "PG::TextEncoder::Array.new.encode: Single 10k batch  allocated #{m.total_allocated} objects, used #{m.total_allocated_memsize / 1024**2} MiB, took #{Time.now - t} seconds"

    t = Time.now
    m = MemoryProfiler.report do
      a.each_slice(10_000) do |slice|
        PG::TextEncoder::Array.new.encode(slice)
        GC.start
      end
    end
    puts "PG::TextEncoder::Array.new.encode: 4M in 10k batches allocated #{m.total_allocated} objects, used #{m.total_allocated_memsize / 1024**2} MiB, took #{Time.now - t} seconds"

  end
end
