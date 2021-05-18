#require_relative '../model/reports/report_manager'

class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/reports/:code')
          .description('Get a report')
          .params(['code', String, 'The report code'])
          .permissions([])
          .returns([200, 'The report JSON'],
                   [400, :error]) \
  do
    json_response({
                    report: ReportManager.registered_reports[params[:code]]
                  })
  end

end
