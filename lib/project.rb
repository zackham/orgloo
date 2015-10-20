class Project
  attr_reader :milestones
  attr_reader :title
  attr_reader :status

  def initialize(title)
    @title = title
    @milestones = []
  end

  def set_project_status
    @milestones.sort!{|a,b| a[:due_on] <=> b[:due_on]}
    m = milestones.last
    if m.nil?
      @status = 'invalid'
    elsif m[:status] == 'done'
      @status = 'done'
    elsif m[:due_on] >= Date.today
      @status = 'active'
    else
      @status = 'stalled'
    end
  end

  def add_milestone(m)
    @milestones << m
  end

  def relevant_milestones
    milestones.select{|m| m[:status] != 'done' && m[:due_on] < (Date.today + 8)}
  end

  def self.milestone_to_s(m)
    m_status = if m[:status]
                 m[:status]
               elsif m[:due_on] < Date.today
                 "LATE"
               elsif m[:due_on] == Date.today
                 "TODAY"
               end

    %(#{m_status}\t#{m[:due_on].to_s} (#{m[:owner]}): #{m[:description]})
  end
end
