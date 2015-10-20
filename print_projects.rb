require_relative 'lib/google_doc_manager'

g = GoogleDocManager.connect

title_filter = ARGV.any? ? ARGV.join(' ') : nil

g.fetch_docs('RWGPS/2015 Projects').each do |d|
  next if title_filter && d.title != title_filter 
  p = ProjectParser.parse_project(d.title, d.export_as_string("text/plain"), !!title_filter)
  puts "(#{p.status}) #{p.title}"
  puts d.human_url
  puts p.relevant_milestones.map{|m| "  " + Project.milestone_to_s(m)}
  puts
end

