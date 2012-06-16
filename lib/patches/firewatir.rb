module FireWatir
  class Firefox
    
    def close

      if js_eval("getWindows().length").to_i == 1
        js_eval("getWindows()[0].close()")

        if current_os == :macosx
          %x{ osascript -e 'tell application "Firefox" to quit' }
        end

        # wait for the app to close properly
        @t.join if @t
      else
        # Check if window exists, because there may be the case that it has been closed by click event on some element.
        # For e.g: Close Button, Close this Window link etc.
        window_number = find_window(:url, @window_url)

        # If matching window found. Close the window.
        if window_number.try(:>, 0)
          js_eval "getWindows()[#{window_number}].close()"
        end

      end
    end
    
    
    
    # Waits for the page to get loaded.
    def wait(last_url = nil)
      #puts "In wait function "
      isLoadingDocument = ""
      start = Time.now

      while isLoadingDocument != "false"
        # MONKEYPATCH - START
        isLoadingDocument = js_eval("#{browser_var}=#{window_var}.getBrowser(); #{browser_var}.webProgress.isLoadingDocument;") rescue return
        # MONKEYPATCH - END
        #puts "Is browser still loading page: #{isLoadingDocument}"

        # Raise an exception if the page fails to load
        if (Time.now - start) > 300
          raise "Page Load Timeout"
        end
      end
      # If the redirect is to a download attachment that does not reload this page, this
      # method will loop forever. Therefore, we need to ensure that if this method is called
      # twice with the same URL, we simply accept that we're done.
      url = js_eval("#{browser_var}.contentDocument.URL")

      if(url != last_url)
        # Check for Javascript redirect. As we are connected to Firefox via JSSh. JSSh
        # doesn't detect any javascript redirects so check it here.
        # If page redirects to itself that this code will enter in infinite loop.
        # So we currently don't wait for such a page.
        # wait variable in JSSh tells if we should wait more for the page to get loaded
        # or continue. -1 means page is not redirected. Anyother positive values means wait.
        jssh_command = "var wait = -1; var meta = null; meta = #{browser_var}.contentDocument.getElementsByTagName('meta');
                                if(meta != null)
                                {
                                    var doc_url = #{browser_var}.contentDocument.URL;
                                    for(var i=0; i< meta.length;++i)
                                    {
                      var content = meta[i].content;
                      var regex = new RegExp(\"^refresh$\", \"i\");
                      if(regex.test(meta[i].httpEquiv))
                      {
                        var arrContent = content.split(';');
                        var redirect_url = null;
                        if(arrContent.length > 0)
                        {
                          if(arrContent.length > 1)
                            redirect_url = arrContent[1];

                          if(redirect_url != null)
                          {
                            regex = new RegExp(\"^.*\" + redirect_url + \"$\");
                            if(!regex.test(doc_url))
                            {
                              wait = arrContent[0];
                            }
                          }
                          break;
                        }
                      }
                    }
                                }
                                wait;"
        wait_time = js_eval(jssh_command).to_i
        begin
          if(wait_time != -1)
            sleep(wait_time)
            # Call wait again. In case there are multiple redirects.
            js_eval "#{browser_var} = #{window_var}.getBrowser()"
            wait(url)
          end
        rescue
        end
      end
      set_browser_document()
      run_error_checks()
      return self
    end
  end
end
