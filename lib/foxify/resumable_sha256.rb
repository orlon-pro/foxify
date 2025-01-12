# frozen_string_literal: true

require "msgpack"

module Foxify
  # A resumable SHA256 implementation
  class ResumableSHA256
    attr_reader :state, :finalized

    def initialize(state = nil, finalized: false)
      @state = state
      @finalized = finalized
      reset unless @state
    end

    def reset
      @state = Foxify::Native.sha256_init
      @finalized = false
      self
    end

    def update(data)
      raise Foxify::Error "Invalid state - you must reset this instance before adding new data" if @finalized

      @state = Foxify::Native.sha256_update(@state, data)
      self
    end

    def hexdigest
      raise Foxify::Error, "Invalid state - this is already finalized" if @finalized

      Foxify::Native.sha256_finalize(@state).tap do
        @finalized = true
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
