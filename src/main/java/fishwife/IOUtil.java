/*
 * Copyright (c) 2011-2017 David Kellum
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you
 * may not use this file except in compliance with the License.  You may
 * obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
 * implied.  See the License for the specific language governing
 * permissions and limitations under the License.
 */

package fishwife;

import static org.jruby.exceptions.RaiseException.createNativeRaiseException;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import org.jcodings.specific.ASCIIEncoding;

import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.Arity;
import org.jruby.runtime.Block;
import org.jruby.runtime.BlockCallback;
import org.jruby.runtime.CallBlock;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;

@JRubyClass( name="Fishwife::IOUtil" )
public class IOUtil
{
    @JRubyMethod( name = "write_file",
                  meta = true,
                  required = 2,
                  argTypes = { RubyObject.class,
                               OutputStream.class } )
    public static IRubyObject writeFile( ThreadContext tc,
                                         IRubyObject klazz,
                                         IRubyObject file,
                                         IRubyObject ostr )
    {
        FileInputStream in = null;
        try {
            try {
                String filePath = file.convertToString().asJavaString();
                in = new FileInputStream( filePath );
                OutputStream out =
                    (OutputStream) ostr.toJava( OutputStream.class );

                final byte[] buff = new byte[ 8 * 1024 ];
                while( true ) {
                    final int len = in.read( buff );
                    if( len > 0 ) {
                        out.write( buff, 0, len );
                    }
                    else break;
                }
                return tc.getRuntime().getNil();
            }
            finally {
                if( in != null ) in.close();
            }
        }
        catch( FileNotFoundException x ) {
            throw createNativeRaiseException( tc.getRuntime(), x );
        }
        catch( IOException x ) {
            throw createNativeRaiseException( tc.getRuntime(), x );
        }
    }

    @JRubyMethod( name = "write_body",
                  meta = true,
                  required = 2,
                  argTypes = { RubyObject.class,
                               OutputStream.class } )
    public static IRubyObject writeBody( ThreadContext tc,
                                         IRubyObject klazz,
                                         IRubyObject body,
                                         IRubyObject out )
    {
        OutputStream ostream = (OutputStream) out.toJava( OutputStream.class );

        RuntimeHelpers.invoke( tc, body, "each",
           CallBlock.newCallClosure( klazz,
                                     tc.getRuntime().getEnumerable(),
                                     Arity.ONE_ARGUMENT,
                                     new AppendBlockCallback( tc.getRuntime(),
                                                              ostream ),
                                                              tc ) );

        return tc.getRuntime().getNil();
    }

    public static final class AppendBlockCallback implements BlockCallback
    {
        public AppendBlockCallback(Ruby runtime, OutputStream out)
        {
            _runtime = runtime;
            _out = out;
        }

        public IRubyObject call( ThreadContext context,
                                 IRubyObject[] args,
                                 Block blk )
        {
            try {
                final RubyString str = args[0].convertToString();
                final ByteList blist = str.getByteList();

                _out.write( blist.unsafeBytes(),
                            blist.begin(),
                            blist.length() );

                return _runtime.getNil();
            }
            catch( IOException x ) {
                throw createNativeRaiseException( _runtime, x );
            }
        }

        private final Ruby _runtime;
        private final OutputStream _out;
    }

    /**
     * Read all bytes of input stream, yielding Ruby String wrapped
     * buffers to block. For efficiency, the buffer backing each
     * String is re-used, so the yielded strings must be consumed (ex:
     * written) and discarded inside the block. The input stream is
     * not closed.
     * @param blen Hint on buffer size (as when a Content-Length is
     * specified) or 0 if no hint, default behavior.
     * @param istr The (java) InputStream, which will not closed.
     * @param block receiving ruby String buffers
     */
    @JRubyMethod( name = "read_input_stream",
                  meta = true,
                  required = 2,
                  argTypes = { Integer.class,
                               InputStream.class } )
    public static IRubyObject readInputStream( ThreadContext tc,
                                               IRubyObject klazz,
                                               IRubyObject blen,
                                               IRubyObject istr,
                                               Block block )
    {
        final Ruby runtime = tc.getRuntime();
        try {
            int max_len = (Integer) blen.toJava( Integer.class );
            InputStream in = (InputStream) istr.toJava( InputStream.class );

            // Default case (max_len == 0) we start with a small
            // buffer to minimize GC overhead, since most requests
            // won't have a body. If a body is found, the buffer is
            // re-allocated larger below
            byte[] buff = new byte[ max_len > 0 ? max_len : 128 ];
            while( true ) {
                final int len = in.read( buff );
                if( len > 0 ) {
                    block.call( tc, toRubyString( runtime, buff, 0, len ) );
                    if( max_len == 0 ) {
                        buff = new byte[ 16*1024 ];
                        max_len = -1; // final buff
                    }
                }
                else break;
            }
            return runtime.getNil();
        }
        catch( IOException x ) {
            throw createNativeRaiseException( runtime, x );
        }
    }

    public static IRubyObject toRubyString( final Ruby runtime,
                                            final byte[] buff,
                                            final int offset,
                                            final int length )
    {
        return new RubyString( runtime,
                               runtime.getString(),
                               new ByteList( buff, offset, length,
                                             ASCIIEncoding.INSTANCE,
                                             false ) );
    }

}
