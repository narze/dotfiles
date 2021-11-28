function _tide_item_gcloud --description "Show Google cloud project"
    type -q gcloud || return
    echo (set_color blue) (gcloud config get-value project)
end
