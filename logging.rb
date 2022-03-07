require 'logger'
VOL_ROTA_LOGGER = Logger.new(STDOUT)
VOL_ROTA_LOGGER.formatter = proc { |severity, datetime, progname, msg|
  "#{severity}, #{datetime}, #{msg}"
}
