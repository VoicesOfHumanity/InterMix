module DialogsHelper
  
  def show_period_instructions(dialog,period)
    if period.instructions.to_s != ''
      template_content = period.instructions
    else
      template_content = render(:partial=>"period_instructions_default",:layout=>false)
    end      
    cdata = {'dialog'=>dialog,'period'=>period}
    template = Liquid::Template.parse(template_content)
    render plain: template.render(cdata)    
  end
  
end
