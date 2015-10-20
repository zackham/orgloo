require 'date'
require_relative 'project' 

# project doc structure
# - milestones_section = "Milestones" \n milestones
# - milestones = "{begin}" sparse_milestones | strict_milestones
# - strict_milestones = milestone | milestone \n strict_milestones
# - sparse_milestones = "{end}" | milestone sparse_milestones | ignored_line sparse_milestones
# - ignored_line = (line that could not be parsed as a milestone)
# - milestone = due_on : description : owner | due_on : description : owner : status
# - due_on = date | date > due_on
# - date = MM/DD | YYYY-MM-DD | TBD
# - description = String
# - owner = String
# - status = "done" | "canceled" | "atrisk" | "ontrack"

class ProjectParser
  def self.parse_project(title, project_str, debug=false)
    pp = new(title, project_str, debug)
    pp.p_project
    pp.project
  end

  attr_reader :project

  def initialize(title, project_str, debug=false)
    @lines = project_str.split("\r\n")
    @pos = 0
    @project = Project.new(title)
    @debug = debug
  end

  def line
    l = @lines[@pos]
    puts l if @debug
    throw "Parsing error - ran off end of doc" if l.nil?
    @pos += 1
    l
  end

  def peek
    @lines[@pos]
  end

  def p_project
    begin
      while line != "Milestones"; end
      p_milestones 
      # we found "Milestones" and no milestones after it, and didn't hit end of doc, keep trying (allow for a table of contents which has a "Milestones" line)
      if @project.milestones.empty?
        p_project 
      end
    rescue
    end
    @project.set_project_status
  end

  def p_milestones
    if peek == "{begin}"
      line
      p_sparse_milestones
    else
      p_strict_milestones
    end
  end

  def p_strict_milestones
    p_strict_milestones if p_milestone
  end

  def p_sparse_milestones
    p_milestone 
    p_sparse_milestones unless peek == "{end}"
  end

  def p_milestone
    parts = line.split(":").map(&:strip)
    return if parts.size < 2
    m = {
      due_on: due_on_from_str(parts[0]),
      description: parts[1],
      owner: parts[2],
      status: status_from_str(parts[3])
    }
    @project.add_milestone(m)
    m
  end

  def due_on_from_str(x)
    date_str = x.split('>').last
    if date_str == "tbd"
      Date.new(2050, 1, 1) 
    else
      begin
        Date.parse(date_str)
      rescue
        throw "#{title} - Invalid date: #{x}"
      end
    end
  end

  def status_from_str(x)
    if [nil, "done", "canceled", "atrisk", "ontrack"].include?(x)
      x 
    else
      throw "Invalid status: #{x}"
    end
  end
end
