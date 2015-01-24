/*
 * Copyright (c) 2011-2015 David Kellum
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

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.runtime.ObjectAllocator;
import org.jruby.runtime.load.BasicLibraryService;

public class JRubyService implements BasicLibraryService
{
    public boolean basicLoad( Ruby runtime )
    {
        RubyModule fmod = runtime.defineModule( "Fishwife" );

        RubyClass ouClass =
            fmod.defineClassUnder( "OutputUtil",
                                   runtime.getObject(),
                                   ObjectAllocator.NOT_ALLOCATABLE_ALLOCATOR );

        ouClass.defineAnnotatedMethods( OutputUtil.class );

        return true;
    }
}
