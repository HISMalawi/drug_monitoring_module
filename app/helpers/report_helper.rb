module ReportHelper

  def stock_movement(params)

html =<<EOF
<html>
  <head>
<script type="text/javascript" src="/javascripts/jquery.js"></script>
<script type="text/javascript" src="/javascripts/Charts/Highcharts/highcharts.js"></script>
<script type="text/javascript" src="/javascripts/Charts/Highcharts/exporting.js"></script>

  </head>
  <body>
    <div id = 'graph'>
        display for graph
    </div>
  </body>
</html>
EOF
    html.html_safe
  end


  def day_deliveries(params, type)

    if params.blank?
      if type.blank?
        html =<<EOF
    <div style="font-size:120%;">  No Deliveries Were Made On This Day</div>
EOF
      else
        html =<<EOF
    <div style="font-size:120%;">  No Deliveries Were Made In This Period</div>
EOF
      end
    else
      html = "
  <table id ='records' border='1' style='width: 99%;margin-right: auto; margin-left: auto'>
    <thead>
        <tr style='background-color: #206BA4'>" +
          "<td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Drug Name</td>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Total Delivered</td>
          <td style='color:#ffffff; font-weight:bold; text-align:center'>Delivery Code </td>"
     if !type.blank?
       html += "<td style='color:#ffffff; font-weight:bold; text-align:center'>Date Delivered</td>"
     end

     html +=  "</tr></thead><tbody>"

      (params || {}).each do |drug, records|
        (records || []).each do |values|
          html += "<tr>
              <td style='padding-left:10px'> #{drug} </td>
              <td style='padding-left:15px'>#{number_with_delimiter(values['value'], :delimeter => ',')} </td>
              <td style='text-align: center'>#{values['code']}</td>"
          if !type.blank?
            html += "<td style='text-align:center'>#{values['date'].to_date.strftime("%d %B %Y")}</td>"
          end
          html += "</tr>"
        end
      end


  html += " </tbody></table>"

    end

    html.html_safe
  end

  def notices_format(results, state)

    html = ""
    case state
      when "new"
        if results.blank?
          html ="<div style='font-size:120%;'> No new notices...</div>"
        else
         html += "<table id ='records' border='1' style='width: 99%;margin-right: auto; margin-left: auto'>
    <thead>
        <tr style='background-color: #206BA4'>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Notice</td>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Day Reported</td>
          <td style='color:#ffffff; font-weight:bold; text-align:center'>Action</td>
          <td style='color:#ffffff; font-weight:bold; text-align:center'>Action</td>
        </tr>
    </thead>
    <tbody>"

          (results || []).each do |notice|
            html += "<tr id=row#{notice.id}><td style='padding-left:10px'> #{notice.notice} </td>
              <td style='padding-left:15px'>#{notice.created_at.strftime('%d, %B, %Y')} </td>
              <td style='text-align: center'>
                  <button class='btn btn-primary' value=#{notice.comments} onClick='viewComment(this.value)'>View Comments</button>
              </td>
              <td style='text-align: center'><input type='submit' class='btn btn-success' value='Manage Notice'
                 onClick='manageNotice(#{notice.id})'/></td></tr>"
          end

         html += " </tbody></table>"
        end
      when "investigating"
        if results.blank?
          html ="<div style='font-size:120%;'> No notices are currently under investigation</div>"
        else

  html +="<table id ='records' border='1' style='width: 99%;margin-right: auto; margin-left: auto'>
    <thead>
        <tr style='background-color: #206BA4'>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Notice</td>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Day Reported</td>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Day Updated</td>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Comments</td>
          <td style='color:#ffffff; font-weight:bold; text-align:center'>Action</td>
        </tr>
    </thead>
    <tbody>"

          (results || []).each do |notice|
            html += "<tr id=row#{notice.id}><td style='padding-left:10px'> #{notice.observation.value_text} </td>
              <td style='padding-left:15px'>#{notice.created_at.strftime('%d, %B, %Y')} </td>
              <td style='text-align: center'>#{notice.updated_at.strftime('%d, %B, %Y')}</td>
              <td style='text-align: center'>
              <button class='btn btn-primary' value=#{notice.comments} onClick='viewComment(this.value)'>View Comments</button>
              </td>
              <td style='text-align: center'><input type='submit' class='btn btn-success' value='Manage Notice'
                    onClick='manageNotice(#{notice.id})'/></td></tr>"
          end

          html += " </tbody></table>"

        end
      when "resolved"
        if results.blank?
          html ="<div style='font-size:120%;'>  No resolved notices are available</div>"
        else
          html += " <table id ='records' border='1' style='width: 99%;margin-right: auto; margin-left: auto'>
    <thead>
        <tr style='background-color: #206BA4'>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Notice</td>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Day Reported</td>
          <td style='color:#ffffff; font-weight:bold; text-align:center'>Day Resolved </td>
          <td style='color:#ffffff; font-weight:bold; text-align:center'>Last Updated By</td>
          <td style='color:#ffffff; font-weight:bold; text-align:center'>Action</td>
        </tr>
    </thead>
    <tbody>"

          (results || []).each do |notice|
              html += "<tr id=row#{notice.id}><td style='padding-left:10px'> #{notice.observation.value_text} </td>
                        <td style='padding-left:15px'>#{notice.created_at.strftime('%d, %B, %Y')} </td>
                        <td style='text-align: center'>#{notice.updated_at.strftime('%d, %B, %Y')}</td>
                        <td style='text-align: center'>#{notice.last_person_to_update}</td>
                        <td style='text-align: center'>
                            <button class='btn btn-primary' value=#{notice.comments} onClick='viewComment(this.value)'>
                            View Comments</button></td></tr>"
          end

          html += " </tbody></table>"

        end
    end

    html.html_safe

  end

  def code_deliveries(params, name)
    if params.blank?
      html =<<EOF
    <div style="font-size:120%;">  No Deliveries With This Code Were Made to #{name}</div>
EOF
    else
      html = "
  <table id ='records' border='1' style='width: 99%;margin-right: auto; margin-left: auto'>
    <thead>
        <tr style='background-color: #206BA4'>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Drug Name</td>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Total Delivered</td>
          <td style='color:#ffffff; font-weight:bold; text-align:center'>Date Delivered </td>
        </tr>
    </thead>
    <tbody>"

      (params || []).each do |records|

          html += "<tr><td style='padding-left:10px'> #{records['drug']} </td><td style='padding-left:15px'>
                  #{number_with_delimiter(records['value'], :delimeter => ',')} </td>
                  <td style='text-align: center'>#{records['date']}</td></tr>"

      end


      html += " </tbody></table>"

    end

    html.html_safe
  end
end

