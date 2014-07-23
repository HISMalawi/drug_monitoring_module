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


  def deliveries(params)

    if params.blank?
    html =<<EOF
    <div style="font-size:120%;">  No Deliveries Were Made On This Day</div>
EOF
    else
      html = "
  <table id ='records' border='1' style='width: 99%;margin-right: auto; margin-left: auto'>
    <thead>
        <tr style='background-color: #206BA4'>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Drug Name</td>
          <td style='color:#ffffff; font-weight:bold;padding-left:10px;'>Total Delivered</td>
          <td style='color:#ffffff; font-weight:bold; text-align:center'>Delivery Code </td>
        </tr>
    </thead>
    <tbody>"

      (params || {}).each do |drug, values|
      html += "<tr><td style='padding-left:10px'> #{drug} </td><td style='padding-left:15px'>#{number_with_delimiter(values['value'], :delimeter => ',')} </td>
              <td style='text-align: center'>#{values['code']}</td></tr>"
      end

  html += " </tbody></table>"

    end

    html.html_safe
  end
end
