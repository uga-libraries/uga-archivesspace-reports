class ResourceCheckUrls < AbstractReport
  register_report(
    params: []
  )

  def query
    results = db.fetch(query_string)
    info[:total_count] = results.count
    results
  end

  def query_string
    <<~SOME_SQL
      SELECT CONVERT(notes USING utf8) AS clean_notes FROM note HAVING instr(clean_notes, 'extref')
    SOME_SQL
  end

  def page_break
    false
  end
  # def notes
  #   "SELECT CONVERT(notes USING utf8) AS clean_notes FROM note HAVING instr(clean_notes, 'extref')
  #     "
  # end
  #
  # def archival_object_titles
  #   'SELECT * FROM archival_object LIMIT 10'
  # end

  def log(s)
    Log.debug(s)
    @job.write_output(s)
  end

end
