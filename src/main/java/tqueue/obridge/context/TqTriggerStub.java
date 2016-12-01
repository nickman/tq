package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class TqTriggerStub {

    private Object rowid;
    private BigDecimal tqueueid;
    private String statuscode;
    private String securitydisplayname;
    private String accountdisplayname;
    private BigDecimal batchid;

    public Object getRowid() {
        return this.rowid;
    }

    public void setRowid(Object rowid) {
        this.rowid = rowid;
    }

    public BigDecimal getTqueueid() {
        return this.tqueueid;
    }

    public void setTqueueid(BigDecimal tqueueid) {
        this.tqueueid = tqueueid;
    }

    public String getStatuscode() {
        return this.statuscode;
    }

    public void setStatuscode(String statuscode) {
        this.statuscode = statuscode;
    }

    public String getSecuritydisplayname() {
        return this.securitydisplayname;
    }

    public void setSecuritydisplayname(String securitydisplayname) {
        this.securitydisplayname = securitydisplayname;
    }

    public String getAccountdisplayname() {
        return this.accountdisplayname;
    }

    public void setAccountdisplayname(String accountdisplayname) {
        this.accountdisplayname = accountdisplayname;
    }

    public BigDecimal getBatchid() {
        return this.batchid;
    }

    public void setBatchid(BigDecimal batchid) {
        this.batchid = batchid;
    }


}
