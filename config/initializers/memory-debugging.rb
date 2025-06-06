# frozen_string_literal: true

started = false
Signal.trap("SIGTRAP") do
  if started
    puts "Performing GC and dumping memory..."
    GC.start
    File.open("/tmp/heap-dump-#{Time.now.to_i}.json","w") { |f| ObjectSpace.dump_all(output: f) }
    puts "Done!"
  else
    ObjectSpace.trace_object_allocations_start
    started = true
    puts "Tracing of memory started"
  end
end
