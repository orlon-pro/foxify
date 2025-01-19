# frozen_string_literal: true

require "digest"

RSpec.describe Foxify::ResumableSHA256 do
  let(:chunk_size) { 1024 * 1024 * 4 }
  let(:lines) { ["The quick brown fox", "jumps over the lazy dog"] }

  subject { Foxify::ResumableSHA256.new }

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
      t = Foxify::ResumableSHA256.new
      t.update(sample)

      expect(t.hexdigest).to eq Digest::SHA256.hexdigest(sample)
    end

    it "calculates the correct value of a string with the class method :hexdigest" do
      sample = "The quick brown fox jumps over the lazy dog"

      expect(subject.class.hexdigest(sample)).to eq Digest::SHA256.hexdigest(sample)
    end

    it "calculates the correct value of a file when updated with chunks" do
      ruby = `which ruby`.chomp

      t = Foxify::ResumableSHA256.new
      input = File.new(ruby)
      until input.eof?
        chunk = input.read(chunk_size) until input.eof?
        t.update chunk
      end

      expect(t.hexdigest).to eq Digest::SHA256.file(ruby).hexdigest
    end

    it "calculates the correct value of a file via the class method :file" do
      ruby = `which ruby`.chomp

      expect(Foxify::ResumableSHA256.file(ruby).hexdigest).to eq Digest::SHA256.file(ruby).hexdigest
    end
  end

  describe "MessagePack support" do
    subject { Foxify::ResumableSHA256.new }

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
      t = Foxify::ResumableSHA256.new

      expect do
        dumped = Marshal.dump(t)
        Marshal.load(dumped) # rubocop:disable Security/MarshalLoad
      end.not_to raise_error
    end

    it "can continue on a restored object to calculate the digest" do
      t = Foxify::ResumableSHA256.new
      t.update(lines.first)

      dumped = Marshal.dump(t)
      loaded = Marshal.load(dumped) # rubocop:disable Security/MarshalLoad

      loaded.update(lines[1])

      control = Digest::SHA256.new
      lines.each { |line| control << line }

      expect(loaded.hexdigest).to eq control.hexdigest
    end
  end
end
