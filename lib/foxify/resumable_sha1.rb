# frozen_string_literal: true

require "msgpack"

module Foxify
  # A resumable SHA1 implementation
  class ResumableSHA1
    CHUNK_SIZE = 1024 * 1024 * 5

    attr_reader :state, :finalized

    def initialize(state = nil, finalized: false)
      @state = state
      @finalized = finalized
      reset unless @state
    end

    def reset
      @state = Foxify::Native.sha1_init
      @finalized = false
      self
    end

    def update(data)
      raise Foxify::Error, "Invalid state - you must reset this instance before adding new data" if @finalized

      @state = Foxify::Native.sha1_update(@state, data)
      self
    end

    alias :<< update

    def write(data)
      update(data)
      data.size
    end

    def hexdigest
      raise Foxify::Error, "Invalid state - this is already finalized" if @finalized

      Foxify::Native.sha1_finalize(@state).tap do
        @finalized = true
      end
    end

    def self.hexdigest(data)
      new.update(data).hexdigest
    end

    def self.file(path)
      new.tap do |t|
        stream = File.open(path, "rb")
        t.update stream.read(CHUNK_SIZE) until stream.eof?
        stream.close
      end
    end

    def ==(other)
      self.class == other.class && state == other.state && finalized == other.finalized
    end

    def to_msgpack
      [@state, @finalized].to_msgpack
    end

    def self.from_msgpack(data)
      state, finalized = MessagePack.unpack(data)
      new(state, finalized:)
    end
  end
end
