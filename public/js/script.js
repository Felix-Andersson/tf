setTimeout(function() {
    document.querySelector('.notice').style.display = 'none';
}, 2000);

function commentClick(comment_nr) {
    var comment =  document.getElementById(`comment_${comment_nr}`)
    comment.style.display = "block"
    comment.classList.add("settings_window");
}

function hideComment(comment_nr) {
    var comment =  document.getElementById(`comment_${comment_nr}`)
    comment.style.display = "none"
    comment.classList.remove("settings_window");
}

const searchbar = document.getElementById('searchbar');
const list = document.getElementById('list');
searchbar.addEventListener('focus', () => { list.classList.toggle('list_toggle') });
searchbar.addEventListener('blur', () => { 
    setTimeout(() => {list.classList.toggle('list_toggle');}, 120); 
});

function search_type() {
    let input = searchbar.value.toLowerCase();
    let gods = document.getElementsByClassName('gods');
    
    for (i = 0; i < gods.length; i++) {
        if (!gods[i].innerHTML.toLowerCase().includes(input)) {
            gods[i].style.display="none";
        } else {
            gods[i].style.display="list-item";
        }
    }
}

function addClick() {
    var resultJSON = document.getElementById('addElement').getAttribute('data-result');
    var result = JSON.parse(resultJSON);

    var element_container = document.getElementById('elementContainer');
    var element_index = element_container.childElementCount + 1;

    var select = document.createElement('select');
    select.name = `element_${element_index}`;

    result.forEach(function(element) {
        var opt = document.createElement('option');
        opt.value = element['id'];
        opt.innerHTML = element['property'];
        select.appendChild(opt);
    });

    element_container.appendChild(select);
}


function removeClick() {
    var element_container = document.getElementById('elementContainer');
    element_container.lastChild.remove()
}
