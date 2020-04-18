# This is the MIT license: http://www.opensource.org/licenses/mit-license.php
#
# Copyright (c) 2005-2012 the SQLAlchemy authors and contributors <see AUTHORS file>.
# SQLAlchemy is a trademark of Michael Bayer.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

from sqlalchemy.testing.suite import *


from sqlalchemy.testing.suite import ComponentReflectionTest as _ComponentReflectionTest

class ComponentReflectionTest(_ComponentReflectionTest):
    @classmethod
    def define_views(cls, metadata, schema):
        return
        for table_name in ('users', 'email_addresses'):
            fullname = table_name
            if schema:
                fullname = "%s.%s" % (schema, table_name)
            view_name = fullname + '_v'
            query = "CREATE VIEW %s AS SELECT * FROM %s" % (
                                view_name, fullname)
            event.listen(
                metadata,
                "after_create",
                DDL(query)
            )
            event.listen(
                metadata,
                "before_drop",
                DDL("DROP VIEW %s" % view_name)
            )
