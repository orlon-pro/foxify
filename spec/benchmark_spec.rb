# frozen_string_literal: true

require "benchmark"
require "digest"

RSpec.describe Foxify do
  describe "benchmarks" do
    let(:chunk_size) { 1024 * 1024 * 4 }

    it "is faster than the normal Digest::SHA256" do
      file = `which ruby`.chomp
      our_sha256 = Benchmark.measure do
        t = Foxify::ResumableSHA256.new
        input = File.new(file)
        until input.eof?
          chunk = input.read(chunk_size) until input.eof?
          t.update chunk
        end
        t.hexdigest
      end

      standard = Benchmark.measure do
        d = Digest::SHA256.new
        input = File.new(file)
        until input.eof?
          chunk = input.read(chunk_size) until input.eof?
          d.update chunk
        end
        d.hexdigest
      end

      expect(our_sha256.total).to be <= standard.total
    end
  end
end
