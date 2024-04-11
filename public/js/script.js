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