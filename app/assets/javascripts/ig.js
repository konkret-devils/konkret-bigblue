if (window !== window.parent){

    $(document).ready(function () {
        let trs = $('tr'),
            i, tr, tr_children;
        for (i=0;i<trs.length;i++){
            tr = $(trs[i]);
            tr_children = tr.children();
            if (tr_children.length === 3){
                let child_0 = $(tr_children[0]);
                if (child_0.children().length === 0 && child_0.text().trim() === 'https://umfrage.onsurvey.de/i_cb/'){
                    let target_origins = [
                        'https://bigblue.konkret-mafo.cloud',
                        'https://bigblue-dev.konkret-mafo.cloud',
                        'https://bigblue-dev2.konkret-mafo.cloud',
                        'https://bigblue-dev3.konkret-mafo.cloud',
                    ];
                    let l = $(tr_children[1]).text().trim();
                    let c = $(tr_children[2]).text().trim();
                    for (let j=0;j<target_origins.length;j++) {
                        window.parent.postMessage(JSON.stringify({t: 'cobrowsing', l: l, c: c}), target_origins[j]);
                    }
                    break;
                }
            }

        }
    });

}