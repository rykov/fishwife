#--
# Copyright (c) 2017 Theo Hultberg, David Kellum
#
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License.  You may
# obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#++

require 'spec_helper'

describe Fishwife::HijackedIO do
  subject :io do
    described_class.new(async_context)
  end

  let :async_context do
    double(:async_context)
  end

  let :buffer do
    StringIO.new
  end

  let :output_stream do
    buffer.to_outputstream
  end

  before do
    response = double(:response)
    async_context.stub(:response).and_return(response)
    async_context.stub(:complete)
    response.stub(:output_stream).and_return(output_stream)
  end

  describe '#write' do
    it 'writes a string to the response output stream' do
      io.write('hello')
      buffer.string.should eq('hello')
    end

    it 'returns the number of bytes written' do
      io.write('hello').should eq(5)
      io.write("\u2603").should eq(3)
    end
  end

  describe '#flush' do
    let :output_stream do
      double(:output_stream)
    end

    before do
      output_stream.stub(:flush)
    end

    it 'flushes the response output stream' do
      output_stream.should_receive(:flush)
      io.flush
    end

    it 'returns self' do
      io.flush.should equal(io)
    end
  end

  [:close, :close_write].each do |method_name|
    describe "##{method_name}" do
      before do
        async_context.stub(:complete)
      end

      it 'completes the async processing' do
        async_context.should_receive(:complete)
        io.send(method_name)
      end

      it 'returns nil' do
        io.send(method_name).should be_nil
      end
    end
  end

  describe '#closed?' do
    context 'before #close has been called' do
      it 'returns false' do
        io.should_not be_closed
      end
    end

    context 'after #close has been called' do
      it 'returns true' do
        io.close
        io.should be_closed
      end
    end
  end
end
