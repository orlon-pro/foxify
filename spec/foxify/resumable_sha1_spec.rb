# frozen_string_literal: true

require "digest"

RSpec.describe Foxify::ResumableSHA1 do
  let(:chunk_size) { 1024 * 1024 * 4 }
  let(:lines) { ["The quick brown fox", "jumps over the lazy dog"] }

  subject { Foxify::ResumableSHA1.new }

  describe "interface" do
    it "responds to :update" do
      expect(subject).to respond_to :update
    end

    it "responds to :hexdigest" do
      expect(subject).to respond_to :hexdigest
    end

    it "responds to :reset" do
      expect(subject).to respond_to :reset
    end

    it "responds to :<<" do
      expect(subject).to respond_to :<<
    end
  end

  describe "class interface" do
    it "responds to :hexdigest" do
      expect(subject.class).to respond_to :hexdigest
    end

    it "responds to :file" do
      expect(subject.class).to respond_to :file
    end
  end

  describe "calculation" do
    it "calculates the correct value of a string" do
      sample = "The quick brown fox jumps over the lazy dog"
      t = Foxify::ResumableSHA1.new
      t.update(sample)

      expect(t.hexdigest).to eq Digest::SHA1.hexdigest(sample)
    end

    it "calculates the correct value of a string with the class method :hexdigest" do
      sample = "The quick brown fox jumps over the lazy dog"

      expect(subject.class.hexdigest(sample)).to eq Digest::SHA1.hexdigest(sample)
    end

    it "calculates the correct value of a file when updated with chunks" do
      ruby = `which ruby`.chomp

      t = Foxify::ResumableSHA1.new
      input = File.new(ruby)
      until input.eof?
        chunk = input.read(chunk_size)
        t.update chunk
      end

      expect(t.hexdigest).to eq Digest::SHA1.file(ruby).hexdigest
    end

    it "calculates the correct value of a file via the class method :file" do
      ruby = `which ruby`.chomp

      expect(Foxify::ResumableSHA1.file(ruby).hexdigest).to eq Digest::SHA1.file(ruby).hexdigest
    end

    it "works correctly with a 24MB sample file" do
      sample = File.join(__dir__, "../files/24mb.random")

      expect(Foxify::ResumableSHA1.file(sample).hexdigest).to eq Digest::SHA1.file(sample).hexdigest
    end
  end

  describe "MessagePack support" do
    subject { Foxify::ResumableSHA1.new }

    it "supports :to_msgpack" do
      expect(subject).to respond_to :to_msgpack
    end

    it "supports .from_msgpack" do
      expect(subject.class).to respond_to :from_msgpack
    end

    it "can properly restore from message pack" do
      data = subject.to_msgpack
      restored = subject.class.from_msgpack(data)

      expect(subject).to eq restored
    end

    it "can properly continue calculation from message pack" do
      subject.update(lines.first)
      dumped = subject.to_msgpack
      loaded = subject.class.from_msgpack(dumped)

      subject.update(lines[1])
      loaded.update(lines[1])

      expect(subject.hexdigest).to eq loaded.hexdigest
    end
  end

  describe "marshalling support" do
    it "allows to dump and load an instance" do
      t = Foxify::ResumableSHA1.new

      expect do
        dumped = Marshal.dump(t)
        Marshal.load(dumped) # rubocop:disable Security/MarshalLoad
      end.not_to raise_error
    end

    it "can continue on a restored object to calculate the digest" do
      t = Foxify::ResumableSHA1.new
      t.update(lines.first)

      dumped = Marshal.dump(t)
      loaded = Marshal.load(dumped) # rubocop:disable Security/MarshalLoad

      loaded.update(lines[1])

      control = Digest::SHA1.new
      lines.each { |line| control << line }

      expect(loaded.hexdigest).to eq control.hexdigest
    end
  end

  describe "error handling" do
    it "raises Foxify::Error when calling update after hexdigest" do
      t = Foxify::ResumableSHA1.new
      t.update("data")
      t.hexdigest

      expect { t.update("more data") }.to raise_error(Foxify::Error)
    end

    it "raises Foxify::Error when calling hexdigest twice" do
      t = Foxify::ResumableSHA1.new
      t.update("data")
      t.hexdigest

      expect { t.hexdigest }.to raise_error(Foxify::Error)
    end
  end

  describe "#reset" do
    it "allows continued use after finalization" do
      t = Foxify::ResumableSHA1.new
      t.update("first")
      t.hexdigest

      t.reset
      t.update("The quick brown fox jumps over the lazy dog")

      expect(t.hexdigest).to eq Digest::SHA1.hexdigest("The quick brown fox jumps over the lazy dog")
    end
  end

  describe "#<<" do
    it "updates the digest and returns self for chaining" do
      t = Foxify::ResumableSHA1.new
      result = t << "The quick brown fox " << "jumps over the lazy dog"

      expect(result).to be t
      expect(t.hexdigest).to eq Digest::SHA1.hexdigest("The quick brown fox jumps over the lazy dog")
    end
  end

  describe "#==" do
    it "returns true for instances with the same state" do
      a = Foxify::ResumableSHA1.new
      a.update("hello")

      b = Foxify::ResumableSHA1.new
      b.update("hello")

      expect(a).to eq b
    end

    it "returns true for two freshly initialized instances" do
      expect(Foxify::ResumableSHA1.new).to eq Foxify::ResumableSHA1.new
    end

    it "returns false for instances with different state" do
      a = Foxify::ResumableSHA1.new
      a.update("hello")

      b = Foxify::ResumableSHA1.new
      b.update("world")

      expect(a).not_to eq b
    end
  end

  describe "empty and binary data" do
    it "calculates the correct digest with no data" do
      expect(Foxify::ResumableSHA1.new.hexdigest).to eq Digest::SHA1.hexdigest("")
    end

    it "handles empty string updates" do
      t = Foxify::ResumableSHA1.new
      t.update("")
      t.update("hello")
      t.update("")

      expect(t.hexdigest).to eq Digest::SHA1.hexdigest("hello")
    end

    it "handles binary data" do
      binary = (0..255).map(&:chr).join
      expect(Foxify::ResumableSHA1.hexdigest(binary)).to eq Digest::SHA1.hexdigest(binary)
    end

    it "handles multi-byte UTF-8 data" do
      utf8 = "\u{1F600}\u{1F4A9}\u{2603}"
      expect(Foxify::ResumableSHA1.hexdigest(utf8)).to eq Digest::SHA1.hexdigest(utf8)
    end
  end

  describe "#reset" do
    it "allows reuse after partial update without finalization" do
      t = Foxify::ResumableSHA1.new
      t.update("partial data")
      t.reset
      t.update("fresh start")

      expect(t.hexdigest).to eq Digest::SHA1.hexdigest("fresh start")
    end
  end

  describe "error handling" do
    it "raises Foxify::Error when calling write after hexdigest" do
      t = Foxify::ResumableSHA1.new
      t.update("data")
      t.hexdigest

      expect { t.write("more data") }.to raise_error(Foxify::Error)
    end
  end

  describe "MessagePack support" do
    it "can restore a finalized instance" do
      t = Foxify::ResumableSHA1.new
      t.update("data")
      t.hexdigest

      restored = Foxify::ResumableSHA1.from_msgpack(t.to_msgpack)
      expect(restored.finalized).to be true
      expect { restored.update("more") }.to raise_error(Foxify::Error)
    end
  end

  describe "IO like methods support" do
    it "supports #write and returns the number of bytes written" do
      t = Foxify::ResumableSHA1.new

      lines.each do |line|
        written = t.write(line)
        expect(written).to eq line.size
      end

      control = Digest::SHA1.new
      lines.each { |line| control << line }
      expect(t.hexdigest).to eq control.hexdigest
    end
  end
end
