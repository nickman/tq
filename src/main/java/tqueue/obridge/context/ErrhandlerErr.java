package tqueue.obridge.context;

import java.sql.Timestamp;
import java.sql.Date;
import java.util.List;
import java.math.BigDecimal;
import java.sql.ResultSet;
import tqueue.obridge.objects.*;
import javax.annotation.Generated;

@Generated("org.obridge.generators.ProcedureContextGenerator")
public class ErrhandlerErr {

    private String functionReturn;
    private String format;
    private List<String> args;

    public String getFunctionReturn() {
        return this.functionReturn;
    }

    public void setFunctionReturn(String functionReturn) {
        this.functionReturn = functionReturn;
    }

    public String getFormat() {
        return this.format;
    }

    public void setFormat(String format) {
        this.format = format;
    }

    public List<String> getArgs() {
        return this.args;
    }

    public void setArgs(List<String> args) {
        this.args = args;
    }


}
