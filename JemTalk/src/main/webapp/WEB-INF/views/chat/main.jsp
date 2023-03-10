<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html>
<head>
		<meta charset="UTF-8">
		<title>KaKao Talk Friend List</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <meta http-equiv="X-UA-Compatible" content="IE-edge">
        <meta name="description" content="Kakao Talk Clone Friend List Page">
        <meta name="keywords" content="KakaoTalk, Clone, Friend">
        <meta name="robotos" content="noindex, nofollow">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/main-layout.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/friend.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/chatting.css">
        <link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/general.css">
        <link rel="preconnect" href="https://fonts.gstatic.com">
        <link href="https://fonts.googleapis.com/css2?family=Nanum+Gothic&display=swap" rel="stylesheet">
       	<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/bootstrap.min.css" />
       	<link rel="stylesheet" href="${pageContext.request.contextPath}/resources/css/bootstrap.css" />
       	<link href="${pageContext.request.contextPath}/resources/css/subModal_bs.sm.css" rel="stylesheet" />
</head>
<script src="https://kit.fontawesome.com/f7fe0761ae.js" crossorigin="anonymous"></script>
<script src="http://code.jquery.com/jquery-latest.min.js"></script>
<script src="${pageContext.request.contextPath}/resources/js/bootstrap.min.js"></script>
<script src="${pageContext.request.contextPath}/resources/js/subModal_bs.sm.js"></script>
<script src="/webjars/sockjs-client/1.1.2/sockjs.min.js"></script>
<script src="/webjars/stomp-websocket/2.3.3-1/stomp.min.js"></script>
<script type="text/javascript">
	sock = new SockJS("/ws-stomp");
	ws = Stomp.over(sock);
	let chatWindow = {};
	reconnect = 0;
	
	$(function(){
		
        connect();

		$(document).on("dblclick","li", function(){	
			var nowRoomNum = $(this).attr("id");
			var nowRoomName = $(this).find(".friend-name").html();
			if(chatWindow[nowRoomNum] == null || chatWindow[nowRoomNum].closed) {
				var totCnt = parseInt($("#totalCnt").html());
				var roomCnt = parseInt($(this).find(".chat-balloon").html());
				$("#totalCnt").html(totCnt - roomCnt);
				$(this).find(".chat-balloon").html("0");
				chatWindow[nowRoomNum] = window.open('/user/EnterRoom?room_num='+ nowRoomNum +"&room_name=" + nowRoomName ,"?????????" + nowRoomNum + " : " + nowRoomName,"width=" + window.innerWidth +", height=" + window.innerHeight + "resizable = no, scrollbars = no");
			}else if (chatWindow[nowRoomNum].closed){
				var totCnt = parseInt($("#totalCnt").html());
				var roomCnt = parseInt($(this).find(".chat-balloon").html());
				$("#totalCnt").html(totCnt - roomCnt);
				$(this).find(".chat-balloon").html("0");
				chatWindow[nowRoomNum] = window.open('/user/EnterRoom?room_num='+ nowRoomNum +"&room_name=" + nowRoomName ,"?????????" + nowRoomNum + " : " +nowRoomName,"width=" + window.innerWidth +", height=" + window.innerHeight + "resizable = no, scrollbars = no");
			}
			else{
				chatWindow[nowRoomNum].focus();
			}
		});
		
		$(document).on("DOMSubtreeModified",".alert-balloon, .chat-balloon", function(){
			if($(this).html() == '0'){
				$(this).hide();
			}else{
				$(this).show();
			}
		});
		
		
		
		$(document).on("click","#friend", function(){
			$("#friend_main").show();
			$("#friend_header").show();
			$("#chat_room_main").hide();
			$("#chat_room_header").hide();
		});
		
		$(document).on("click","#chat_list", function(){
			$("#friend_main").hide();
			$("#friend_header").hide();
			$("#chat_room_main").show();
			$("#chat_room_header").show();
		});
		
		$(document).on("click","#make_room", function(){
			/* var user_nums = [];
			var user_names = [];

			user_nums.push("14");
			user_names.push("??????");
			user_nums.push("15");
			user_names.push("??????");
			
			
			var message ={
					type       : "CREATE", 
					room_name  : "????????????",
					user_nums   : user_nums,
					msg_content   : user_names + "?????? ??????????????????",
					user_num : '${chatUser.user_num }',
					user_name : '${chatUser.user_name }'
			}
			 ws.send("/pub/chat/message", {}, JSON.stringify(message)); */
			searchFriend();
		});
		
		$(document).on("click","#add_friend", function(){
			findFriend();
		});
		
		$(document).on("click","#makeRoomName", function(){
			var user_names = [];
			$('input:checkbox[name="userCheck"]:checked').each(function(index, item) {
						var userInfo = $(item).val().split(',');
						user_names.push(userInfo[1]);
			});
			user_names.push('${chatUser.user_name }');
			$('#roomName').val(user_names.toString());
			$('#my-submodal').submodal("show");
		});

		$(document).on("click","#createRoom", function(){
			var user_nums = [];
			var user_names = [];
			$('input:checkbox[name="userCheck"]:checked').each(function(index, item) {
						var userInfo = $(item).val().split(',');
						user_nums.push(userInfo[0]);
						user_names.push(userInfo[1]);
			});
			user_nums.push('${chatUser.user_num }');
			
			var message ={
					type       : "CREATE", 
					room_name  : $('#roomName').val(),
					user_nums   : user_nums,
					msg_content   : user_names + "?????? ??????????????????",
					msg_type : 0,
					user_num : '${chatUser.user_num }',
					user_name : '${chatUser.user_name }'
			}
			ws.send("/pub/chat/message", {}, JSON.stringify(message));
			$("#searchName").html("");
			$('#my-submodal').submodal("hide");
			$('#exampleModal2').modal("hide");
			
		});
		
		$(document).on("change","input[name='userCheck']", function(){
			$(this).next("i").toggleClass("fa-solid").toggleClass("fa-regular");
		});
		
		$(document).on("click",".userCheck", function(){
			var checkBoxes = $(this).find("input[name='userCheck']");
			checkBoxes.prop('checked',!checkBoxes.prop("checked")).trigger('change');
		});
		
		$(document).on("keyup","#searchName", function(key){
			if(key.keyCode==13) {
				searchFriend();
	        }
		});
		
		/* $(document).on("propertychange change keyup paste input","#searchName", function(){
			searchFriend();
		}); */
		
		
		
		
		/* $(document).on("click","#others", function(){
			$("#friend_main").hide();
			$("#chat_room_main").hide();
		}); */
	});
	
	function recevieMsg(msg){
		console.log(msg.room_num);
		$("#" + msg.room_num).find(".chat-content").html(msg.msg_content);
		$("#" + msg.room_num).find("time").html(msg.send_date);
		var roomCnt = parseInt($("#" + msg.room_num).find(".chat-balloon").html()) + 1;
		var totCnt = parseInt($("#totalCnt").html()) + 1;
		console.log("totCnt -> " + totCnt);
		console.log("roomCnt -> " + roomCnt);
		$("#" + msg.room_num).insertBefore('#chat_room_main ul li:eq(0)');
		if(chatWindow[msg.room_num] == null || chatWindow[msg.room_num].closed) {
			$("#" + msg.room_num).find(".chat-balloon").html(roomCnt);
			$("#totalCnt").html(totCnt);
		}else if (chatWindow[msg.room_num].closed){
			$("#" + msg.room_num).find(".chat-balloon").html(roomCnt);
			$("#totalCnt").html(totCnt);
		}else{
			chatWindow[msg.room_num].receiveMsg(msg);
		}
	}
	
	function someoneEnter(msg){
		if(msg.user_num != '${chatUser.user_num}'){
			if(chatWindow[msg.room_num] == null) {
			}else if (chatWindow[msg.room_num].closed){
			}else{
				chatWindow[msg.room_num].someoneEnter(msg.log_num);
			}
		}
	}
	
	function searchFriend(){
		 $.ajax({
				url:"/user/findUserList",
				type : "POST",
				data : {"searchName" : $("#searchName").val()},
				dataType:'json',
				success:function(data){
					var str ="";
					$(data).each(function(){
						str +=	"<tr class='userCheck'><td style='width : 20%;'><img src='${pageContext.request.contextPath}/resources/pic/default.png' class='profile-img' alt='k?????????????????????'></td>"
						str +=	"<td style='width : 60%;'>"+ this.user_name +"</td>"
						str +=	"<td style='width : 20%;'><input type='checkbox' name='userCheck' id='search"+ this.user_num + "' value='"+this.user_num+","+ this.user_name +"'>";
						str +=  "<i class='fa-regular fa-circle-check'></i></td></tr>"
					});
					$("#ajaxItemList").html(str);
					$('#exampleModal2').modal("show");
				}
		});
	}
	
	function findFriend(){
		 $.ajax({
				url:"/user/findFriendList",
				type : "POST",
				data : {"searchName" : $("#searchMail").val()},
				dataType:'json',
				success:function(data){
					var str ="";
					$(data).each(function(){
						str +=	"<tr class='userCheck'><td style='width : 20%;'><img src='${pageContext.request.contextPath}/resources/pic/default.png' class='profile-img' alt='k?????????????????????'></td>"
						str +=	"<td style='width : 60%;'>"+ this.user_name +"</td>"
						str +=	"<td style='width : 20%;'><input type='checkbox' name='userCheck' id='search"+ this.user_num + "' value='"+this.user_num+","+ this.user_name +"'>";
						str +=  "<i class='fa-regular fa-circle-check'></i></td></tr>"
					});
					$("#ajaxItemList3").html(str);
					$('#exampleModal3').modal("show");
				}
		});
	}
	
	function connect() {
        // pub/sub event
        ws.connect({}, function(frame) {
        	alert("?????? ??????");
            ws.subscribe("/sub/user/${chatUser.user_num}", function(message) {
               alert("?????? ????????? ??????");
               	var msg = JSON.parse(message.body);
               	var str = "<li id='" + msg.room_num + "'><div class='click_btn'>"
               	str +=	"<img src='${pageContext.request.contextPath}/resources/pic/default.png' class='profile-img' alt='k?????????????????????'>"
               	str +=  "<div class='talk'><p class='friend-name'>" + msg.room_name +"</p>"
               	str +=  "<p class='chat-content'>" + msg.msg_content +"</p></div>"
               	str += 	"<div class='chat-status'><time datetime='" + msg.send_date +"'>" + msg.send_date +"</time>"
               	if(msg.user_num == '${chatUser.user_num }'){
               		chatWindow[msg.room_num] = window.open('/user/createRoomResult?room_num='+ msg.room_num +"&room_name=" +msg.room_name, msg.room_name,"width=" + window.innerWidth +", height=" + window.innerHeight + "resizable = no, scrollbars = no");
               		str += "<span class='chat-balloon' style='display:none;'>0</span>"
               	}else{
               		var totCnt = parseInt($("#totalCnt").html()) + 1;
               		$("#totalCnt").html(totCnt);
               		str += "<span class='chat-balloon'>1</span></div></div></li>"
               	}
               	$("#chat_room_main ul").prepend(str);
               	
               	
               	
               	ws.subscribe("/sub/chat/room/" + msg.room_num, function(message) {
	        		var msg = JSON.parse(message.body);
	        		if(msg.type != 'ENTER'){
	        			recevieMsg(msg);
	        		}else{
	        			someoneEnter(msg);
	        		}
               	});
            });
            
            <c:forEach var="chatRooms" items="${mainPageinfo.chatRooms }">
	            ws.subscribe("/sub/chat/room/${chatRooms.room_num}", function(message) {
	        		var msg = JSON.parse(message.body);
	        		if(msg.type != 'ENTER'){
	        			recevieMsg(msg);
	        		}else{
	        			someoneEnter(msg);
	        		}
	            });
            </c:forEach>
            /* $.ajax(
    				{
    					url:"/user/mainPage",
    					dataType:'json',
    					success:function(data){
    						var str = "<div id='friend_main'><div><ul><li>";
    		                str += "<img src='${pageContext.request.contextPath}/resources/pic/me.png' alt='?????????????????????'>";
    		                str += "<div class='profile'> <p>${chatUser.user_name}</p><p>??????????????? ??????</p>";
    		                str += "</div></li></ul></div>";              
    		                str += "<div><div class='profile-title'><h2>??????</h2><p>3</p></div><ul>"        
    		               	$(data.chatFriends).each(function(){
    							str += "<li><img src='${pageContext.request.contextPath}/resources/pic/default.png'>";
    							str += "<div class='profile'><p id='" + this.user_num +"'>"+this.user_name;
    							str += "<p>??????????????? ??????</p></div></li>";
    						});
    		                str += "</ul></div></div>";

    		                str += " <div id='chat_room_main' style='display: none;'><ul>";     
    		               	$(data.chatRooms).each(function(){
    		               		ws.subscribe("/sub/chat/room/" + this.room_num, function(message) {
    		                        console("????????? ?????? ??????????" + this.room_name);
    		                        var msg = JSON.parse(message.body);
    		                        if(chatWindow[this.room_num]==null || chatWindow[this.room_num].closed){
    		                        	
    		            			}else{
    		            				var chat = 
    		            			}
    		                    });
    							str += "<li id='" + this.room_num +"'><div class='click_btn'><img src='${pageContext.request.contextPath}/resources/pic/default.png' class='profile-img' alt='k?????????????????????'>";
    							str += "<div class='talk'><p class='friend-name'>"+ this.room_name +"</p>";
    							str += "<p class='chat-content'>"+ this.last_log +"</p></div>";
    							str += "<div class='chat-status'><time datetime='" + this.send_date +"'>" + this.send_date + "</time>";
    							if(this.msg_cnt=='0'){
    								str += "<span class='chat-balloon' style='display:none;'>" + this.msg_cnt + "</span>";
    							}else{
    								str += "<span class='chat-balloon'>" + this.msg_cnt + "</span>";
    							}
    							str += "</div></div></li>";
    						});
    		                str += "</ul></div>";
    		                $("main").html(str);
    		                $("#totalCnt").html(data.totCnt);
    					}
    				}		
    		); */
        }, function(error) {
            if(reconnect++ <= 5) {
                setTimeout(function() {
                	console.log("?????? ?????? ?????? ?????????...")
                    connect();
                },10*1000);
            }
        });
    }

</script>
<body>
	 <div id="content">
            <!-- ?????????(?????????, ?????? ?????? ???) -->
            <div class="setting_bar">
                <i class="icon-window-minimize" alt="???????????????" title="?????????"></i>
                <i class="icon-window-maximize" alt="???????????????" title="?????????"></i>
                <i class="icon-cancel" alt="????????????" title="??????"></i>
            </div>
            <!-- ??????: ??????, ?????? ?????? ??????, ?????? ?????? ?????? -->
            <header>
            	<div id="friend_header">
	                <h1>??????</h1>
	                <i class="fa-solid fa-user-plus" id="add_friend"></i>
	                <!-- <i class="fa-solid fa-magnifying-glass" id="find_friend"></i> -->
	            </div>
	            <div id="chat_room_header" style="display: none;">
	                <h1>??????</h1>
	                <i class="fa-solid fa-comment-medical" id="make_room"></i>
	                <i class="fa-solid fa-magnifying-glass" id="find_room"></i>
	            </div>
            </header>
            <!-- ?????????, ?????????, ????????? ??? ?????? ????????? ??????????????? -->
            <nav>
                <div class="main-menu">
                    <div id="friend" class="click_btn" title="??????">
                        <i class="fa-solid fa-user"></i>
                    </div>
                    <div id="chat_list" class="click_btn" title="??????">
                        <i class="fa-solid fa-comment"></i>
                        <c:choose>
			    			<c:when test="${mainPageinfo.totCnt eq '0'}">
			    				<span class="alert-balloon" alt="?????????" id="totalCnt" style='display:none;'>${mainPageinfo.totCnt}</span>
			    			</c:when>
			    			<c:otherwise>
			    				<span class="alert-balloon" alt="?????????" id="totalCnt"> ${mainPageinfo.totCnt} </span>
			    			</c:otherwise>
			    		</c:choose>
                    </div>
                    <!-- <div id="others" class="click_btn" title="?????????">
                        <i class="fa-solid fa-ellipsis"></i>
                        <span class="alert-balloon" alt="?????????">N</span>
                    </div> -->
                </div>
                <div class="sub-menu">
                    <a href="temp.html" target="_blank">
                        <i class="icon-smile" alt="???????????????????????????" title="???????????????"></i></a>
                    <i class="icon-bell" alt="????????????" title="??????"></i>
                    <i class="icon-cog" alt="????????????" title="??????"></i>
                </div>
            </nav>
            <!-- ??????: ????????? ?????? ?????? -->
            <main>
	            <div id='friend_main'>
	            	<div>
		            	<ul>
		            		<li>
	    		                <img src='${pageContext.request.contextPath}/resources/pic/me.png' alt='?????????????????????'>
	    		                <div class='profile'> <p>${chatUser.user_name}</p><p>??????????????? ??????</p>
	    		                </div>
	    		            </li>
	    		        </ul>
    		       </div>
    		       <div>
    		       		<div class='profile-title'>
	    		       		<h2>??????</h2>
	    		       		<p>3</p>
    		       		</div>
    		       		<ul>
    		       			<c:forEach var="chatFriends" items="${mainPageinfo.chatFriends }">
    		       				<li>
    		       					<img src='${pageContext.request.contextPath}/resources/pic/default.png'>
    		       					<div class='profile'><p id="${chatFriends.user_num}">
    		       						${chatFriends.user_name}
    		       					<p>??????????????? ??????</p></div></li>
    		       			</c:forEach>
    		            </ul>
    		       </div>
    		   </div>
    		   
    		    <div id='chat_room_main' style='display: none;'>
    		    	<ul>
    		    		<c:forEach var="chatRooms" items="${mainPageinfo.chatRooms }">
	    					<li id="${chatRooms.room_num }">
	    						<div class='click_btn'>
	    							<img src='${pageContext.request.contextPath}/resources/pic/default.png' class='profile-img' alt='k?????????????????????'>
	    							<div class='talk'>
	    								<p class='friend-name'>${chatRooms.room_name}</p>
	    								<p class='chat-content'>${chatRooms.last_log}</p>
	    							</div>
	    							<div class='chat-status'>
	    									<time datetime="${chatRooms.send_date}">${chatRooms.send_date}</time>
			    							<c:choose>
			    								<c:when test="${chatRooms.msg_cnt eq '0'}">
			    									<span class='chat-balloon' style='display:none;'>${chatRooms.msg_cnt}</span>
			    								</c:when>
			    								<c:otherwise>
			    									<span class='chat-balloon'> ${chatRooms.msg_cnt} </span>
			    								</c:otherwise>
			    							</c:choose>
	    							</div>
	    						</div>
	    					</li>
    					</c:forEach>
					</ul>
				</div>
	        </main>
	            <!-- aside: ?????? -->
	            <aside>
	                <img src="${pageContext.request.contextPath}/resources/pic/ad.png" alt="???????????????">
	            </aside>
        </div>
        
        <!-- =============Modal Start==================== -->
			<div class="modal fade" id="exampleModal2" tabindex="-1"
				aria-labelledby="exampleModalLabel" aria-hidden="true">
				<div class="modal-dialog">
					<div class="modal-content">
						<div class="modal-header">
							<h4 class="modal-title" id="exampleModalLabel"
								style="border: 3px;">?????? ??????</h4>
							<button type="button" class="btn-close" data-bs-dismiss="modal"
								aria-label="Close"></button>
						</div>
						<div class="modal-body">
							<!-- SUBMODAL -->
                            <div class="modal submodal" id="my-submodal">
                                <div class="modal-dialog">
                                    <div class="modal-content">
                                        <div class="modal-body">
                                            <p class="text-center">????????? ??????</p>
                                            <hr />
                                            <form class="form-horizontal">
                                                <div class="form-group">
                                                    <label class="col-sm-3 control-label" for="pass">????????? ??????</label>
                                                    <div class="col-sm-9">
                                                        <input type="text" class="form-control" id="roomName">
                                                    </div>
                                                </div>
                                            </form>
                                        </div>
                                        <div class="modal-footer">
                                            <button class="btn btn-secondary" data-dismiss="submodal" aria-hidden="true">??????</button>
                                            <button class="btn btn-primary" id="createRoom">??????</button>
                                        </div>
                                    </div>
                                </div>
                            </div>
          					<!-- /SUBMODAL -->
							<div class="col-12 rounded-bottom overflow-auto bg-light p-3"
								style="min-height: 550px;">
								<input type="text" class="form-control" name="searchName" id="searchName" placeholder="???????????? ??????????????????.">
								<table class="table table-hover">
									<thead>
									</thead>
									<tbody id="ajaxItemList">
									</tbody>
								</table>
							</div>
						</div>
						<div class="modal-footer">
							<button type="button" class="btn btn-secondary"
								data-bs-dismiss="modal">??????</button>
							<button type="button" class="btn btn-primary"
								id="makeRoomName">??????</button>
						</div>
					</div>
				</div>
			</div>	
				<!-- =================Modal end====================== -->
				
				
			  <!-- =============Modal Start==================== -->
			<div class="modal fade" id="exampleModal3" tabindex="-1"
				aria-labelledby="exampleModalLabel" aria-hidden="true">
				<div class="modal-dialog">
					<div class="modal-content">
						<div class="modal-header">
							<h4 class="modal-title" id="exampleModalLabel"
								style="border: 3px;">?????? ??????</h4>
							<button type="button" class="btn-close" data-bs-dismiss="modal"
								aria-label="Close"></button>
						</div>
						<div class="modal-body">

							<div class="col-12 rounded-bottom overflow-auto bg-light p-3"
								style="min-height: 550px;">
								<input type="text" class="form-control" name="searchName" id="searchMail" placeholder="???????????? ??????????????????.">
								<table class="table table-hover">
									<thead>
									</thead>
									<tbody id="ajaxItemList3">
									</tbody>
								</table>
							</div>
						</div>
						<div class="modal-footer">
							<button type="button" class="btn btn-secondary"
								data-bs-dismiss="modal">??????</button>
							<button type="button" class="btn btn-primary"
								id="addFriend">??????</button>
						</div>
					</div>
				</div>
			</div>	
				<!-- =================Modal end====================== -->
			
</body>
</html>