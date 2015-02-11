################################################################################
# BMC Software, Inc.
# Confidential and Proprietary
# Copyright (c) BMC Software, Inc. 2001-2012
# All Rights Reserved.
################################################################################

#
# Rajesh Jangam: 12/13/2012
# With JRUBY 1.7.1, there is a big problem with the oracle enhanced adapter
# while returning non-ASCII values from the database
# We had to fix the way values are returned for String and CLOBs:
# Basically get the raw bytes some how and then convert them to their UTF-8 equivalents
#


if OracleAdapter
module ActiveRecord
  module ConnectionAdapters

    class OracleEnhancedJDBCConnection < OracleEnhancedConnection #:nodoc:
      require 'java'
      require File.join(Rails.root, 'lib', 'commons-io-2.4.jar')

      def lob_to_ruby_value(val)
        case val
        when ::Java::OracleSql::CLOB
          if val.isEmptyLob
            nil
          else
            ::Java::OrgApacheCommonsIo::IOUtils.toByteArray(val.getCharacterStream, "UTF-8").to_a.pack('C*').force_encoding('utf-8')
          end
        when ::Java::OracleSql::BLOB
          if val.isEmptyLob
            nil
          else
            String.from_java_bytes(val.getBytes(1, val.length))
          end
        end
      end

      def get_ruby_value_from_result_set(rset, i, type_name, get_lob_value = true)
        case type_name
        when :NUMBER
          d = rset.getNUMBER(i)
          if d.nil?
            nil
          elsif d.isInt
            Integer(d.stringValue)
          else
            BigDecimal.new(d.stringValue)
          end
        when :VARCHAR2, :CHAR, :LONG, :NVARCHAR2, :NCHAR
          b = rset.getBytes(i)
          if b
            b.to_a.pack('C*').force_encoding('utf-8')
          else
            nil
          end
        when :DATE
          if dt = rset.getDATE(i)
            d = dt.dateValue
            t = dt.timeValue
            if OracleEnhancedAdapter.emulate_dates && t.hours == 0 && t.minutes == 0 && t.seconds == 0
              Date.new(d.year + 1900, d.month + 1, d.date)
            else
              Time.send(Base.default_timezone, d.year + 1900, d.month + 1, d.date, t.hours, t.minutes, t.seconds)
            end
          else
            nil
          end
        when :TIMESTAMP, :TIMESTAMPTZ, :TIMESTAMPLTZ, :"TIMESTAMP WITH TIME ZONE", :"TIMESTAMP WITH LOCAL TIME ZONE"
          ts = rset.getTimestamp(i)
          ts && Time.send(Base.default_timezone, ts.year + 1900, ts.month + 1, ts.date, ts.hours, ts.minutes, ts.seconds,
            ts.nanos / 1000)
        when :CLOB
          get_lob_value ? lob_to_ruby_value(rset.getClob(i)) : rset.getClob(i)
        when :BLOB
          get_lob_value ? lob_to_ruby_value(rset.getBlob(i)) : rset.getBlob(i)
        when :RAW
          raw_value = rset.getRAW(i)
          raw_value && raw_value.getBytes.to_a.pack('C*')
        else
          nil
        end
      end

    end
  end
end
end