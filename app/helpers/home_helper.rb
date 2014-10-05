module HomeHelper
  def config_form_element_group keys = [], config = {}, label = true
    keys.map do |field|
      content_tag('p', class: 'form-label-and-element') do
        name= "config[#{field}]"
        label_tag(name, label ? field.capitalize : "") + number_field_tag(
           name, config[field], min: 0.0, step: 0.01, class: 'numeric')
      end
    end.join('')
  end
end
