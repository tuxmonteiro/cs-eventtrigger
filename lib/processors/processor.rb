
require_relative '../util/abstract_interface'

class Processor
  include AbstractInterface

  needs_implementation :on_create, :id, :projectid, :jobresult
  needs_implementation :on_destroy, :id, :jobresult

end