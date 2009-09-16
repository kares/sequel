# Allows the use of named timezones via TZInfo (requires tzinfo).
# Forces the use of DateTime as Sequel's datetime_class, since
# ruby's Time class doesn't support timezones other than local
# and UTC.
#
# This allows you to either pass strings or TZInfo::Timezone
# instance to Sequel.database_timezone=, application_timezone=, and
# typecast_timezone=.  If a string is passed, it is converted to a
# TZInfo::Timezone using TZInfo::Timezone.get.
#
# Let's say you have the database server in New York and the
# application server in Los Angeles.  For historical reasons, data
# is stored in local New York time, but the application server only
# services clients in Los Angeles, so you want to use New York
# time in the database and Los Angeles time in the application.  This
# is easily done via:
#
#   Sequel.database_timezone = 'America/New_York'
#   Sequel.application_timezone = 'America/Los_Angeles'
#
# Then, before data is stored in the database, it is converted to New
# York time.  When data is retrieved from the database, it is
# converted to Los Angeles time.

require 'tzinfo'

module Sequel
  self.datetime_class = DateTime
  
  %w'application database typecast'.each do |t|
    instance_eval("def #{t}_timezone=(tz); @#{t}_timezone = tz.is_a?(String) ? TZInfo::Timezone.get(tz) : tz; end", __FILE__, __LINE__)
  end
  
  # Assume the given DateTime has a correct time but a wrong timezone.  It is
  # currently in UTC timezone, but it should be converted to the input_timzone.
  # Keep the time the same but convert the timezone to the input_timezone.
  # Expects the input_timezone to be a TZInfo::Timezone instance.
  def self.convert_input_datetime_other(v, input_timezone) # :nodoc:
    local_offset = input_timezone.period_for_local(v).utc_total_offset_rational
    (v - local_offset).new_offset(local_offset)
  end

  # Convert the given DateTime to use the given output_timezone.
  # Expects the output_timezone to be a TZInfo::Timezone instance.
  def self.convert_output_datetime_other(v, output_timezone) # :nodoc:
    # TZInfo converts times, but expects the given DateTime to have an offset
    # of 0 and always leaves the timezone offset as 0
    v = output_timezone.utc_to_local(v.new_offset(0))
    local_offset = output_timezone.period_for_local(v).utc_total_offset_rational
    # Convert timezone offset from UTC to the offset for the output_timezone
    (v - local_offset).new_offset(local_offset)
  end
  
  private_class_method :convert_input_datetime_other, :convert_output_datetime_other
end
