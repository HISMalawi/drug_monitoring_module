module ApplicationHelper
  def app_name
    title=<<EOF
    Drug Monitoring Dashboard
EOF

  end

  def organization_name
    'Ministry Of Health'
  end

  def about_organization
    <<EOF
    <b>HIV unit</b><br />
    M&E team.
EOF

  end

  def print_content(str)                                                           
    return '' if str.blank?                                                     
    str.html_safe.gsub(/\r\n?/,"<br/>")                                         
  end

  def admin?
    unless User.current.blank?
      User.current.user_roles.map(&:role).include?('admin') rescue true
    end
  end

  def quater(date)
    month = date.month
    if month <= 3
      return "Q1 #{date.year}" 
    elsif month >= 4 and month <= 6
      return "Q2 #{date.year}" 
    elsif month >= 7 and month <= 9
      return "Q3 #{date.year}" 
    else
      return "Q4 #{date.year}" 
    end
  end

  def category(level)
    if (level < 25)                                                              
      return "Below Market Min"                                                  
    elsif (level >= 25 and level <= 49.9)                                        
      return "Factory Min-Market Min"                                            
    elsif (level < 50)                                                           
      return "< Factory Min"                                                     
    elsif (level >= 50 && level <= 84)
      return "Production Range"                                                  
    elsif (level > 84)                                                           
      return "> Factory Max"                                                     
    end
  end

end



