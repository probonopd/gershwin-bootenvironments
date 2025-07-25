SUBDIR += sysutils

PORTSTOP=	yes

.include <bsd.port.subdir.mk>

GIT?= git
.if !target(update)
update:
.if exists(${.CURDIR}/.git)
	@echo "--------------------------------------------------------------"
	@echo ">>> Updating ${.CURDIR} from git repository"
	@echo "--------------------------------------------------------------"
	cd ${.CURDIR}; ${GIT} pull
.endif
.endif
